# Info_ADComputers

PowerShell script to export detailed Active Directory computer information to CSV format.

## Description

This script queries Active Directory to retrieve all computer objects and exports the information to a CSV file with semicolon (`;`) delimiter.

## Prerequisites

- Active Directory PowerShell module installed
- Read permissions on Active Directory
- Windows PowerShell 5.1 or higher

## Exported Information

The script exports the following fields for each computer:

| Field | Description |
|-------|-------------|
| **Name** | Computer account name |
| **OperatingSystem** | Operating system name (e.g., Windows Server 2022, Windows 11) |
| **OperatingSystemVersion** | Operating system version number |
| **Enabled** | Account status (True/False) |
| **PrimaryGroup** | Primary group (Domain Computers, Domain Controllers, etc.) |
| **Path** | Canonical path in Active Directory (OU structure) |
| **Created** | Account creation date (dd/MM/yyyy format) |
| **Modified** | Last modification date (dd/MM/yyyy format) |
| **LastLogon** | Last logon timestamp (dd/MM/yyyy format or "Never") |
| **InactiveOver180Days** | Indicates if computer hasn't logged on for more than 180 days (True/False) |
| **PasswordLastSet** | Last password change date (dd/MM/yyyy format or "Never") |
| **EncryptionTypes** | Supported Kerberos encryption types (DES, RC4, AES 128, AES 256) |

## Usage

```powershell
.\Info_ADComputers.ps1
```

## Output

The CSV file is generated at:
```
C:\temp\Info_ADComputers_[date].csv
```

**Example:** `C:\temp\Info_ADComputers_05-01-2026.csv`

### Output file characteristics:
- **Delimiter:** Semicolon (;)
- **Encoding:** UTF-8
- **Date format:** dd/MM/yyyy

## Notes

- The `C:\temp` folder is automatically created if it doesn't exist
- The filename includes the execution date to avoid overwrites
- Computers that have never logged on are marked as inactive
- Encryption types are decoded from numeric values to readable names

## Additional Features

### Inactive Computer Identification
The script automatically identifies computers that haven't logged on in the last 180 days, facilitating cleanup operations and infrastructure audits.

### Encryption Types Decoding
Kerberos encryption types are translated from numeric codes to understandable names (DES, RC4, AES 128/256), useful for security audits and identifying systems with obsolete protocols.

### Primary Group Recognition
The primary group RID is converted to the group name, allowing easy distinction between domain member computers, writable Domain Controllers, and Read-Only Domain Controllers (RODC).

### Operating System Information
Exports both the name and version of the operating system, facilitating infrastructure inventory and update planning.

## Output Example

```csv
Name;OperatingSystem;OperatingSystemVersion;Enabled;PrimaryGroup;Path;Created;Modified;LastLogon;InactiveOver180Days;PasswordLastSet;EncryptionTypes
SRV-DC01;Windows Server 2022 Standard;10.0 (20348);True;Domain Controllers (writable);contoso.com/Domain Controllers;15/06/2020;04/01/2026;05/01/2026;False;01/12/2025;RC4, AES 128, AES 256
PC-WKS01;Windows 11 Pro;10.0 (22631);True;Domain Computers;contoso.com/Computers/Workstations;20/10/2023;03/01/2026;04/01/2026;False;15/12/2025;RC4, AES 128, AES 256
```

## Use Cases

- **Infrastructure inventory:** Get a complete list of all domain computers with details on operating system and version
- **Security audit:** Identify computers with obsolete encryption protocols or disabled accounts
- **Active Directory cleanup:** Locate inactive computers to remove or disable
- **Compliance:** Document computer status for compliance reports
- **Update planning:** Identify obsolete operating systems that need updating

## License

See the [LICENSE](../../../../LICENSE) file in the repository root.
