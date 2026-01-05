<#
.SYNOPSIS
    Export Active Directory user information to CSV.

.DESCRIPTION
    This script queries Active Directory for all user accounts and exports detailed information to a CSV file.
    
    Exported information includes:
    - Name: User's full name
    - sAMAccountName: User's login name (SAM account name)
    - Enabled: Account status (True/False)
    - PrimaryGroup: Primary group membership (Domain Users, etc.)
    - AccountNotDelegated: Delegation restriction status
    - Path: Canonical path in Active Directory (OU structure)
    - PasswordLastSet: Last password change date (dd/MM/yyyy format)
    - PasswordExpiry: Password expiration date (dd/MM/yyyy format or "Never")
    - PasswordNeverExpires: Password expiration policy (True/False)
    - Created: Account creation date (dd/MM/yyyy format)
    - Modified: Last modification date (dd/MM/yyyy format)
    - LastLogon: Last logon timestamp (dd/MM/yyyy format or "Never")
    - InactiveOver180Days: Indicates if user hasn't logged on for more than 180 days (True/False)
    - EncryptionTypes: Supported Kerberos encryption types (DES, RC4, AES 128, AES 256, or combinations)

.NOTES
    Output file: C:\temp\Info_ADUsers_[date].csv
    Delimiter: Semicolon (;)
    Encoding: UTF-8
    Requires: Active Directory PowerShell module
#>

# Configuration
$folder = "C:\temp"
$date = Get-Date -Format "dd-MM-yyyy"
$logFile = "$folder\Info_ADUsers_$date.csv"

# Create folder if it doesn't exist
if (-not (Test-Path -Path $folder)) {
    New-Item -ItemType Directory -Path $folder -Force | Out-Null
}

# Function to decode encryption types
function Get-EncryptionTypeName {
    param([int]$Value)
    
    $encryptionTypes = @{
        0  = "Not defined - defaults to RC4_HMAC_MD5"
        1  = "DES_CBC_CRC"
        2  = "DES_CBC_MD5"
        3  = "DES_CBC_CRC, DES_CBC_MD5"
        4  = "RC4"
        5  = "DES_CBC_CRC, RC4"
        6  = "DES_CBC_MD5, RC4"
        7  = "DES_CBC_CRC, DES_CBC_MD5, RC4"
        8  = "AES 128"
        9  = "DES_CBC_CRC, AES 128"
        10 = "DES_CBC_MD5, AES 128"
        11 = "DES_CBC_CRC, DES_CBC_MD5, AES 128"
        12 = "RC4, AES 128"
        13 = "DES_CBC_CRC, RC4, AES 128"
        14 = "DES_CBC_MD5, RC4, AES 128"
        15 = "DES_CBC_CRC, DES_CBC_MD5, RC4, AES 128"
        16 = "AES 256"
        17 = "DES_CBC_CRC, AES 256"
        18 = "DES_CBC_MD5, AES 256"
        19 = "DES_CBC_CRC, DES_CBC_MD5, AES 256"
        20 = "RC4, AES 256"
        21 = "DES_CBC_CRC, RC4, AES 256"
        22 = "DES_CBC_MD5, RC4, AES 256"
        23 = "DES_CBC_CRC, DES_CBC_MD5, RC4, AES 256"
        24 = "AES 128, AES 256"
        25 = "DES_CBC_CRC, AES 128, AES 256"
        26 = "DES_CBC_MD5, AES 128, AES 256"
        27 = "DES_CBC_CRC, DES_CBC_MD5, AES 128, AES 256"
        28 = "RC4, AES 128, AES 256"
        29 = "DES_CBC_CRC, RC4, AES 128, AES 256"
        30 = "DES_CBC_MD5, RC4, AES 128, AES 256"
        31 = "DES_CBC_CRC, DES_CBC_MD5, RC4-HMAC, AES128-CTS-HMAC-SHA1-96, AES256-CTS-HMAC-SHA1-96"
    }
    
    if ($null -eq $Value) { return "No Value" }
    return $encryptionTypes[$Value]
}

# Function to get primary group name
function Get-PrimaryGroupName {
    param([int]$GroupID)
    
    switch ($GroupID) {
        513 { return "Domain Users" }
        514 { return "Domain Guests" }
        515 { return "Domain Computers" }
        516 { return "Domain Controllers" }
        default { 
            if ($GroupID -gt 2600) { return "Custom Group (RID: $GroupID)" }
            else { return "Unknown Group (RID: $GroupID)" }
        }
    }
}

Write-Host "Querying Active Directory users..." -ForegroundColor Cyan

# Query AD and process data using pipeline
$users = Get-ADUser -Filter * -Properties Name, sAMAccountName, Enabled, primaryGroupID, 
    AccountNotDelegated, canonicalName, pwdLastSet, 'msDS-UserPasswordExpiryTimeComputed', 
    PasswordNeverExpires, whenCreated, whenChanged, LastLogonTimestamp, 'msDS-SupportedEncryptionTypes' |
    Select-Object Name, sAMAccountName, Enabled,
        @{Name='PrimaryGroup'; Expression={ Get-PrimaryGroupName $_.primaryGroupID }},
        AccountNotDelegated,
        @{Name='Path'; Expression={ $_.canonicalName -replace [regex]::Escape("/$($_.Name)"), '' }},
        @{Name='PasswordLastSet'; Expression={ 
            if ($_.pwdLastSet -and $_.pwdLastSet -gt 0) { 
                [DateTime]::FromFileTime($_.pwdLastSet).ToString("dd/MM/yyyy") 
            } else { "Never" }
        }},
        @{Name='PasswordExpiry'; Expression={ 
            if ($_.'msDS-UserPasswordExpiryTimeComputed' -and $_.'msDS-UserPasswordExpiryTimeComputed' -gt 0) { 
                [DateTime]::FromFileTime($_.'msDS-UserPasswordExpiryTimeComputed').ToString("dd/MM/yyyy") 
            } else { "Never" }
        }},
        PasswordNeverExpires,
        @{Name='Created'; Expression={ $_.whenCreated.ToString("dd/MM/yyyy") }},
        @{Name='Modified'; Expression={ $_.whenChanged.ToString("dd/MM/yyyy") }},
        @{Name='LastLogon'; Expression={ 
            if ($_.LastLogonTimestamp -and $_.LastLogonTimestamp -gt 0) { 
                [DateTime]::FromFileTime($_.LastLogonTimestamp).ToString("dd/MM/yyyy") 
            } else { "Never" }
        }},
        @{Name='InactiveOver180Days'; Expression={ 
            if ($_.LastLogonTimestamp -and $_.LastLogonTimestamp -gt 0) {
                [DateTime]::FromFileTime($_.LastLogonTimestamp) -lt (Get-Date).AddDays(-180)
            } else { $true }
        }},
        @{Name='EncryptionTypes'; Expression={ Get-EncryptionTypeName $_.'msDS-SupportedEncryptionTypes' }}

Write-Host "Exporting to CSV..." -ForegroundColor Cyan

# Export to CSV with proper encoding
$users | Export-Csv -Path $logFile -Delimiter ';' -NoTypeInformation -Encoding UTF8

Write-Host "File created successfully: $logFile" -ForegroundColor Green
Write-Host "Total users exported: $($users.Count)" -ForegroundColor Green

pause