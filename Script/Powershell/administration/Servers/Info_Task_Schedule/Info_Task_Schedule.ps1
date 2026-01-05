<#
.SYNOPSIS
    Retrieves scheduled tasks information from remote computers and exports to CSV.

.DESCRIPTION
    This script collects Windows scheduled tasks information from multiple computers
    either from a file list or from Active Directory OU.
    
    The script queries scheduled tasks and exports the following data:
    - Server Name, Task Name, Location, Author, Description
    - Run Task User, Run Level, Logon Type
    - Execute, Parameters, Status

.NOTES
    Author: WeAreProject®
    Date: January 2026
    Requires: Active Directory module (for OU option)
    Requires: PowerShell Remoting enabled on target computers
#>

# Initialize variables
$folder = "C:\temp\"
$date = Get-Date -Format "dd-MM-yyyy"

# Create temp folder if it doesn't exist
if (!(Test-Path -Path $folder)) {
    New-Item -ItemType Directory -Path $folder -Force | Out-Null
}

$logFile = "$folder\Info_Task_Schedule_$date.csv"
$script:GlobalCredential = $null

# Function to display menu
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

# Function to get credentials for remote access
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

# Function to get scheduled tasks from remote computer
function Get-RemoteScheduledTasks {
    param (
        [Parameter(Mandatory)]
        [string]$ComputerName
    )
    
    try {
        # Test connectivity
        if (!(Test-Connection -ComputerName $ComputerName -Count 1 -Quiet -ErrorAction SilentlyContinue)) {
            Write-Host "$ComputerName - NOT reachable (ping failed)" -ForegroundColor Red
            return [PSCustomObject]@{
                ServerName     = $ComputerName
                TaskName       = "Not reachable"
                Location       = "N/A"
                Author         = "N/A"
                Description    = "N/A"
                RunTaskUser    = "N/A"
                RunLevel       = "N/A"
                LogonType      = "N/A"
                Execute        = "N/A"
                Parameters     = "N/A"
                Status         = "Not reachable"
            }
        }
        
        Write-Host "$ComputerName - Reachable, retrieving scheduled tasks..." -ForegroundColor Green
        
        # Prepare script block to execute remotely
        $scriptBlock = {
            Get-ScheduledTask -TaskName * -ErrorAction SilentlyContinue | 
                Select-Object TaskName, TaskPath, Author, Description, State, 
                              @{N='UserID';E={$_.Principal.UserID}},
                              @{N='RunLevel';E={$_.Principal.RunLevel}},
                              @{N='LogonType';E={$_.Principal.LogonType}},
                              @{N='Execute';E={$_.Actions.Execute -join '; '}},
                              @{N='Arguments';E={$_.Actions.Arguments -join '; '}}
        }
        
        # Execute command with or without credentials
        $tasks = if ($script:GlobalCredential) {
            Invoke-Command -ComputerName $ComputerName -Credential $script:GlobalCredential -ScriptBlock $scriptBlock -ErrorAction Stop
        } else {
            Invoke-Command -ComputerName $ComputerName -ScriptBlock $scriptBlock -ErrorAction Stop
        }
        
        if ($tasks) {
            Write-Host "$ComputerName - Found $($tasks.Count) scheduled tasks" -ForegroundColor Cyan
            
            # Create output objects
            $results = foreach ($task in $tasks) {
                [PSCustomObject]@{
                    ServerName     = $ComputerName
                    TaskName       = $task.TaskName
                    Location       = $task.TaskPath
                    Author         = $task.Author
                    Description    = $task.Description
                    RunTaskUser    = $task.UserID
                    RunLevel       = $task.RunLevel
                    LogonType      = $task.LogonType
                    Execute        = $task.Execute
                    Parameters     = $task.Arguments
                    Status         = $task.State
                }
            }
            
            return $results
        } else {
            Write-Host "$ComputerName - No scheduled tasks found" -ForegroundColor Yellow
            return $null
        }
    }
    catch {
        $errorMsg = $_.Exception.Message
        
        # Simplify common error messages
        if ($errorMsg -match "WinRM|Kerberos") {
            $errorMsg = "WinRM/Authentication error"
        } elseif ($errorMsg -match "access denied") {
            $errorMsg = "Access denied - Check permissions"
        }
        
        Write-Host "$ComputerName - ERROR: $errorMsg" -ForegroundColor Red
        
        return [PSCustomObject]@{
            ServerName     = $ComputerName
            TaskName       = "Error"
            Location       = "N/A"
            Author         = "N/A"
            Description    = $errorMsg
            RunTaskUser    = "N/A"
            RunLevel       = "N/A"
            LogonType      = "N/A"
            Execute        = "N/A"
            Parameters     = "N/A"
            Status         = "Error"
        }
    }
}

# Option 1: Load computers from file
function Get-TasksFromFile {
    # Prompt for file path
    $filePath = Read-Host "Enter the file path (e.g., C:\Service\server_list.txt)"

    # Validate file exists
    if (!(Test-Path -Path $filePath)) {
        Write-Host ""
        Write-Host "ERROR: File not found at: $filePath" -ForegroundColor Red
        Write-Host "Press any key to exit..."
        pause
        return
    }
    
    # Load computer list from file
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
    
    # Collect scheduled tasks from all computers
    Write-Host "Querying scheduled tasks..." -ForegroundColor Cyan
    $allResults = @()
    $successCount = 0
    $errorCount = 0
    
    foreach ($computer in $computerList) {
        $computerName = $computer.Trim()
        if ($computerName) {
            $results = Get-RemoteScheduledTasks -ComputerName $computerName
            
            if ($results) {
                $allResults += $results
                
                # Track success/errors
                if ($results[0].Status -notmatch "Error|Not reachable") {
                    $successCount++
                } else {
                    $errorCount++
                }
            }
        }
    }
    
    # Export to CSV
    if ($allResults.Count -gt 0) {
        $allResults | Export-Csv -Path $logFile -NoTypeInformation -Delimiter ";" -Encoding UTF8
        
        Write-Host "`n========================================" -ForegroundColor Cyan
        Write-Host "File created successfully: $logFile" -ForegroundColor Green
        Write-Host "Total records: $($allResults.Count)" -ForegroundColor Cyan
        Write-Host "Successful: $successCount | Errors: $errorCount" -ForegroundColor $(if($errorCount -gt 0){'Yellow'}else{'Green'})
        Write-Host "========================================" -ForegroundColor Cyan
    } else {
        Write-Host "`nNo data collected" -ForegroundColor Yellow
    }
    
    pause
}

# Option 2: Load computers from Active Directory OU
function Get-TasksFromAD {
    # Check if AD module is available
    if (!(Get-Module -ListAvailable -Name ActiveDirectory)) {
        Write-Host "ERROR: Active Directory module not found. Please install RSAT tools." -ForegroundColor Red
        pause
        return
    }
    
    Import-Module ActiveDirectory -ErrorAction SilentlyContinue
    
    # Prompt for OU path
    $ouPath = Read-Host "Enter the OU DistinguishedName (e.g., OU=Servers,OU=Production,DC=lab,DC=local)"
    
    Write-Host "`nQuerying Active Directory..." -ForegroundColor Cyan
    
    try {
        # Get computers from AD
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
        
        # Collect scheduled tasks from all computers
        Write-Host "Querying scheduled tasks..." -ForegroundColor Cyan
        $allResults = @()
        $successCount = 0
        $errorCount = 0
        
        foreach ($computer in $computers) {
            $results = Get-RemoteScheduledTasks -ComputerName $computer.Name
            
            if ($results) {
                $allResults += $results
                
                # Track success/errors
                if ($results[0].Status -notmatch "Error|Not reachable") {
                    $successCount++
                } else {
                    $errorCount++
                }
            }
        }
        
        # Export to CSV
        if ($allResults.Count -gt 0) {
            $allResults | Export-Csv -Path $logFile -NoTypeInformation -Delimiter ";" -Encoding UTF8
            
            Write-Host "`n========================================" -ForegroundColor Cyan
            Write-Host "File created successfully: $logFile" -ForegroundColor Green
            Write-Host "Total records: $($allResults.Count)" -ForegroundColor Cyan
            Write-Host "Successful: $successCount | Errors: $errorCount" -ForegroundColor $(if($errorCount -gt 0){'Yellow'}else{'Green'})
            Write-Host "========================================" -ForegroundColor Cyan
        } else {
            Write-Host "`nNo data collected" -ForegroundColor Yellow
        }
        
        pause
    }
    catch {
        Write-Host "ERROR querying Active Directory: $_" -ForegroundColor Red
        Write-Host "Please verify the OU path is correct" -ForegroundColor Yellow
        pause
    }
}

# Main script execution
Show-Menu -Title 'Powered By WeAreProject®'
$selection = Read-Host "Please make a selection"

switch ($selection) {
    '1' {
        Get-TasksFromFile
    }
    '2' {
        Get-TasksFromAD
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
