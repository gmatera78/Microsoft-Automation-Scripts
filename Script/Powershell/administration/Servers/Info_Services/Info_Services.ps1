<#
.SYNOPSIS
    Retrieves service information from remote computers and exports to CSV.

.DESCRIPTION
    This script collects Windows service information from multiple computers
    either from a file list or from Active Directory OU.

.NOTES
    Author: Gianluca Matera
    Date: January 2026
    Requires: Active Directory module (for OU option)
#>

$folder = "C:\temp\"
$date = Get-Date -Format "dd-MM-yyyy"

# Create temp folder if it doesn't exist
if (!(Test-Path -Path $folder)) {
    New-Item -ItemType Directory -Path $folder -Force | Out-Null
}

$logFile = "$folder\Info_Services_$date.csv"

# Global credential variable
$script:GlobalCredential = $null

# Function to show menu
function Show-Menu {
    param (
        [string]$Title = "Powered By WeAreProject®"
    )
    Clear-Host
    Write-Host "================ $Title ================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "1: Load computers/servers from file" -ForegroundColor Green
    Write-Host "2: Load computers/servers from Active Directory OU" -ForegroundColor Green
    Write-Host "Q: Quit" -ForegroundColor Yellow
    Write-Host ""
}

# Function to get credentials
function Get-RemoteCredential {
    $useCredential = Read-Host "Do you want to use specific credentials? (Y/N)"
    
    if ($useCredential -match '^[Yy]') {
        Write-Host "Enter credentials for remote access" -ForegroundColor Cyan
        $script:GlobalCredential = Get-Credential -Message "Enter credentials for remote computers"
        
        if ($script:GlobalCredential) {
            Write-Host "Credentials saved. Will use: $($script:GlobalCredential.UserName)" -ForegroundColor Green
        } else {
            Write-Host "No credentials provided. Will use current user context." -ForegroundColor Yellow
        }
    } else {
        Write-Host "Using current user context" -ForegroundColor Yellow
        $script:GlobalCredential = $null
    }
}

# Function to get services from remote computer with credential support
function Get-RemoteServiceInfo {
    param (
        [Parameter(Mandatory)]
        [string]$ComputerName
    )
    
    try {
        # Test connectivity
        if (!(Test-Connection -ComputerName $ComputerName -Count 1 -Quiet -ErrorAction SilentlyContinue)) {
            Write-Host "$ComputerName - NOT reachable (ping failed)" -ForegroundColor Red
            return [PSCustomObject]@{
                ServerName  = $ComputerName
                StartName   = "Not reachable"
                State       = "Not reachable"
                DisplayName = "Not reachable"
                StartMode   = "Not reachable"
            }
        }
        
        Write-Host "$ComputerName - Reachable, retrieving services..." -ForegroundColor Green
        
        $services = $null
        $cimSessionOptions = New-CimSessionOption -Protocol Dcom
        
        # Try with credentials first if available
        if ($script:GlobalCredential) {
            try {
                Write-Host "  Attempting connection with provided credentials..." -ForegroundColor Cyan
                $cimSession = New-CimSession -ComputerName $ComputerName -Credential $script:GlobalCredential -SessionOption $cimSessionOptions -ErrorAction Stop
                $services = Get-CimInstance -ClassName Win32_Service -CimSession $cimSession -ErrorAction Stop |
                    Select-Object Name, StartName, State, DisplayName, StartMode
                Remove-CimSession -CimSession $cimSession -ErrorAction SilentlyContinue
            }
            catch {
                Write-Host "  Failed with credentials, trying fallback methods..." -ForegroundColor Yellow
                Remove-CimSession -CimSession $cimSession -ErrorAction SilentlyContinue
            }
        }
        
        # Try without credentials (current user context) using DCOM
        if (-not $services) {
            try {
                Write-Host "  Attempting connection with current user (DCOM)..." -ForegroundColor Cyan
                $cimSession = New-CimSession -ComputerName $ComputerName -SessionOption $cimSessionOptions -ErrorAction Stop
                $services = Get-CimInstance -ClassName Win32_Service -CimSession $cimSession -ErrorAction Stop |
                    Select-Object Name, StartName, State, DisplayName, StartMode
                Remove-CimSession -CimSession $cimSession -ErrorAction SilentlyContinue
            }
            catch {
                Write-Host "  DCOM failed, trying WinRM..." -ForegroundColor Yellow
                Remove-CimSession -CimSession $cimSession -ErrorAction SilentlyContinue
            }
        }
        
        # Last resort: try with WinRM and current credentials
        if (-not $services) {
            try {
                Write-Host "  Attempting WinRM connection..." -ForegroundColor Cyan
                if ($script:GlobalCredential) {
                    $cimSession = New-CimSession -ComputerName $ComputerName -Credential $script:GlobalCredential -ErrorAction Stop
                } else {
                    $cimSession = New-CimSession -ComputerName $ComputerName -ErrorAction Stop
                }
                $services = Get-CimInstance -ClassName Win32_Service -CimSession $cimSession -ErrorAction Stop |
                    Select-Object Name, StartName, State, DisplayName, StartMode
                Remove-CimSession -CimSession $cimSession -ErrorAction SilentlyContinue
            }
            catch {
                Write-Host "  All connection methods failed" -ForegroundColor Red
                Remove-CimSession -CimSession $cimSession -ErrorAction SilentlyContinue
                throw "Unable to connect: $_"
            }
        }
        
        if ($services) {
            Write-Host "$ComputerName - Found $($services.Count) services" -ForegroundColor Cyan
            
            # Create output objects
            $results = foreach ($service in $services) {
                [PSCustomObject]@{
                    ServerName  = $ComputerName
                    StartName   = $service.StartName
                    State       = $service.State
                    DisplayName = $service.DisplayName
                    StartMode   = $service.StartMode
                }
            }
            
            return $results
        } else {
            throw "No services retrieved"
        }
    }
    catch {
        $errorMsg = $_.Exception.Message
        
        # Simplify common error messages
        if ($errorMsg -match "WinRM.*Kerberos|0x80090322") {
            $errorMsg = "Authentication failed (Kerberos/WinRM)"
        } elseif ($errorMsg -match "access denied|0x80070005") {
            $errorMsg = "Access denied - Check permissions"
        } elseif ($errorMsg -match "RPC.*unavailable|0x800706BA") {
            $errorMsg = "RPC unavailable - Firewall blocking?"
        }
        
        Write-Host "$ComputerName - ERROR: $errorMsg" -ForegroundColor Red
        
        return [PSCustomObject]@{
            ServerName  = $ComputerName
            StartName   = "Error: $errorMsg"
            State       = "Error"
            DisplayName = "Authentication/Connection Failed"
            StartMode   = "Error"
        }
    }
}

# Option 1: Load from file
function Get-ServicesFromFile {
    $filePath = Read-Host "Enter the file path (e.g., C:\Service\server_list.txt)"
    
    if (!(Test-Path $filePath)) {
        Write-Host "ERROR: File not found at $filePath" -ForegroundColor Red
        pause
        return
    }
    
    Write-Host "`nLoading computer list from file..." -ForegroundColor Cyan
    $computerList = Get-Content $filePath | Where-Object { $_.Trim() -ne "" }
    
    if ($computerList.Count -eq 0) {
        Write-Host "ERROR: No computers found in file" -ForegroundColor Red
        pause
        return
    }
    
    Write-Host "Found $($computerList.Count) computers`n" -ForegroundColor Green
    
    # Ask for credentials
    Get-RemoteCredential
    Write-Host ""
    
    $allResults = @()
    $successCount = 0
    $errorCount = 0
    
    foreach ($computer in $computerList) {
        $results = Get-RemoteServiceInfo -ComputerName $computer.Trim()
        $allResults += $results
        
        # Track success/errors
        if ($results[0].State -notmatch "Error|Not reachable") {
            $successCount++
        } else {
            $errorCount++
        }
    }
    
    # Export to CSV
    $allResults | Export-Csv -Path $logFile -NoTypeInformation -Delimiter ";" -Encoding UTF8
    Write-Host "`n========================================" -ForegroundColor Cyan
    Write-Host "File created successfully: $logFile" -ForegroundColor Green
    Write-Host "Total records: $($allResults.Count)" -ForegroundColor Cyan
    Write-Host "Successful: $successCount | Errors: $errorCount" -ForegroundColor $(if($errorCount -gt 0){'Yellow'}else{'Green'})
    Write-Host "========================================" -ForegroundColor Cyan
    pause
}
# Option 2: Load from Active Directory OU
function Get-ServicesFromAD {
    # Check if AD module is available
    if (!(Get-Module -ListAvailable -Name ActiveDirectory)) {
        Write-Host "ERROR: Active Directory module not found. Please install RSAT tools." -ForegroundColor Red
        pause
        return
    }
    
    Import-Module ActiveDirectory -ErrorAction SilentlyContinue
    
    $ouPath = Read-Host "Enter the OU DistinguishedName (e.g., OU=Servers,OU=Production,DC=lab,DC=local)"
    
    Write-Host "`nQuerying Active Directory..." -ForegroundColor Cyan
    
    try {
        $computers = Get-ADComputer -SearchBase $ouPath -Filter * -Properties Name -ErrorAction Stop
        
        if ($computers.Count -eq 0) {
            Write-Host "ERROR: No computers found in OU: $ouPath" -ForegroundColor Red
            pause
            return
        }
        
        Write-Host "Found $($computers.Count) computers in AD`n" -ForegroundColor Green
        
        # Ask for credentials
        Get-RemoteCredential
        Write-Host ""
        
        $allResults = @()
        $successCount = 0
        $errorCount = 0
        
        foreach ($computer in $computers) {
            $results = Get-RemoteServiceInfo -ComputerName $computer.Name
            $allResults += $results
            
            # Track success/errors
            if ($results[0].State -notmatch "Error|Not reachable") {
                $successCount++
            } else {
                $errorCount++
            }
        }
        
        # Export to CSV
        $allResults | Export-Csv -Path $logFile -NoTypeInformation -Delimiter ";" -Encoding UTF8
        Write-Host "`n========================================" -ForegroundColor Cyan
        Write-Host "File created successfully: $logFile" -ForegroundColor Green
        Write-Host "Total records: $($allResults.Count)" -ForegroundColor Cyan
        Write-Host "Successful: $successCount | Errors: $errorCount" -ForegroundColor $(if($errorCount -gt 0){'Yellow'}else{'Green'})
        Write-Host "========================================" -ForegroundColor Cyan
        pause
    }
    catch {
        Write-Host "ERROR querying Active Directory: $_" -ForegroundColor Red
        pause
    }
}

# Main script execution
Show-Menu -Title 'Powered By WeAreProject®'
$selection = Read-Host "Please make a selection"

switch ($selection) {
    '1' {
        Get-ServicesFromFile
    }
    '2' {
        Get-ServicesFromAD
    }
    'Q' {
        Write-Host "Exiting..." -ForegroundColor Yellow
        exit
    }
    default {
        Write-Host "Invalid selection. Please run the script again." -ForegroundColor Red
        pause
    }
}
