# Info_ADUsers

Author: Gianluca Matera

PowerShell script to export detailed Active Directory user information to CSV format.

## Description

This script queries Active Directory to retrieve all user accounts and exports the information to a CSV file with semicolon (`;`) delimiter.

## Prerequisites

- Active Directory PowerShell module installed
- Read permissions on Active Directory
- Windows PowerShell 5.1 or higher

## Exported Information

The script exports the following fields for each user:

| Field | Description |
|-------|-------------|
| **Name** | User's full name |
| **sAMAccountName** | User's login name (SAM account name) |
| **Enabled** | Account status (True/False) |
| **PrimaryGroup** | Primary group membership (e.g., Domain Users) |
| **AccountNotDelegated** | Delegation restriction status |
| **Path** | Canonical path in Active Directory (OU structure) |
| **PasswordLastSet** | Last password change date (dd/MM/yyyy format) |
| **PasswordExpiry** | Password expiration date (dd/MM/yyyy format or "Never") |
| **PasswordNeverExpires** | Password expiration policy (True/False) |
| **Created** | Account creation date (dd/MM/yyyy format) |
| **Modified** | Last modification date (dd/MM/yyyy format) |
| **LastLogon** | Last logon timestamp (dd/MM/yyyy format or "Never") |
| **InactiveOver180Days** | Indicates if user hasn't logged on for more than 180 days (True/False) |
| **EncryptionTypes** | Supported Kerberos encryption types (DES, RC4, AES 128, AES 256) |

## Usage

```powershell
.\info_ADUsers.ps1
```

## Output

The CSV file is generated at:
```
C:\temp\Info_ADUsers_[date].csv
```

**Example:** `C:\temp\Info_ADUsers_05-01-2026.csv`

### Output file characteristics:
- **Delimiter:** Semicolon (;)
- **Encoding:** UTF-8
- **Date format:** dd/MM/yyyy

## Notes

- The `C:\temp` folder is automatically created if it doesn't exist
- The filename includes the execution date to avoid overwrites
- Users who have never logged on are marked as inactive
- Encryption types are decoded from numeric values to readable names

## Additional Features

### Inactive User Identification
The script automatically identifies users who haven't logged on in the last 180 days, facilitating cleanup operations and audits.

### Encryption Types Decoding
Kerberos encryption types are translated from numeric codes to understandable names (DES, RC4, AES 128/256), useful for security audits.

### Primary Groups
The primary group RID is converted to the group name (e.g., 513 → "Domain Users").

## Output Example

```csv
Name;sAMAccountName;Enabled;PrimaryGroup;AccountNotDelegated;Path;PasswordLastSet;PasswordExpiry;PasswordNeverExpires;Created;Modified;LastLogon;InactiveOver180Days;EncryptionTypes
John Doe;jdoe;True;Domain Users;False;contoso.com/Users;01/12/2025;01/03/2026;False;15/06/2020;03/01/2026;04/01/2026;False;RC4, AES 128, AES 256
```

## License

See the [LICENSE](../../../../LICENSE) file in the repository root.
