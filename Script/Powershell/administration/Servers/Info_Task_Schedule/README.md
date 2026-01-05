# Info_Task_Schedule.ps1

Author: Gianluca Matera

## Overview

**Info_Task_Schedule.ps1** is a PowerShell script designed to retrieve detailed information about scheduled tasks from multiple Windows servers or computers. The script queries remote systems and exports comprehensive task data to a CSV file for analysis and reporting.

## Features

- ✅ **Multiple Input Methods**: Load computers from a text file or Active Directory OU
- 🔐 **Credential Support**: Optionally use specific credentials for remote access
- 📊 **Comprehensive Data Collection**: Retrieves all scheduled task properties
- 🛡️ **Error Handling**: Robust error management with connectivity testing
- 📁 **CSV Export**: Structured output in CSV format with UTF-8 encoding
- 📈 **Progress Reporting**: Real-time status updates and final statistics
- 🎨 **Color-Coded Output**: Easy-to-read console output with color indicators

## Prerequisites

### Required
- **PowerShell 5.1** or higher
- **PowerShell Remoting** enabled on target computers
- **Network connectivity** to target servers
- **Appropriate permissions** to query scheduled tasks remotely

### Optional
- **Active Directory PowerShell Module** (RSAT) - Required only for AD OU queries

### Enable PowerShell Remoting
On target computers, run as Administrator:
```powershell
Enable-PSRemoting -Force
```

## Installation

1. Download the script to your local machine
2. Ensure execution policy allows script execution:
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

## Usage

### Running the Script

```powershell
.\Info_Task_Schedule.ps1
```

### Menu Options

When you run the script, you'll see a menu with the following options:

```
================ Powered By WeAreProject® ================

1: Load computers/servers from file
2: Load computers/servers from Active Directory OU
Q: Quit
```

### Option 1: Load from File

1. Select option `1`
2. Provide the full path to a text file containing computer names (one per line)
   - Example: `C:\Service\server_list.txt`
3. Choose whether to use specific credentials (Y/N)
4. Script will query each computer and export results

**Example file format (server_list.txt):**
```
SERVER01
SERVER02
SERVER03
DC01
```

### Option 2: Load from Active Directory OU

1. Select option `2`
2. Enter the DistinguishedName of the OU
   - Example: `OU=Servers,OU=Production,DC=lab,DC=local`
3. Choose whether to use specific credentials (Y/N)
4. Script will query all computers in the OU and export results

## Credential Options

The script will ask if you want to use specific credentials:

- **Yes (Y)**: A credential prompt will appear where you can enter username and password
  - Use domain credentials: `DOMAIN\username` or `username@domain.com`
  - Useful for cross-domain scenarios or elevated permissions
  
- **No (N)**: Script will use your current user context
  - Requires your current user to have permissions on remote systems

## Output

### CSV File Location
```
C:\temp\Info_Task_Schedule_dd-MM-yyyy.csv
```

### CSV Columns
The exported CSV file contains the following information:

| Column | Description |
|--------|-------------|
| **ServerName** | Computer/server name |
| **TaskName** | Name of the scheduled task |
| **Location** | Task path/folder location |
| **Author** | Task creator/author |
| **Description** | Task description |
| **RunTaskUser** | User account the task runs as |
| **RunLevel** | Privilege level (Limited/Highest) |
| **LogonType** | How the task logs on (Interactive/Password/S4U/etc.) |
| **Execute** | Executable or script being run |
| **Parameters** | Command-line arguments |
| **Status** | Task state (Ready/Running/Disabled/etc.) |

### Console Output

During execution, you'll see:
- ✅ Green: Successful connections and operations
- ❌ Red: Connection failures and errors
- ℹ️ Cyan: Progress information
- ⚠️ Yellow: Warnings

Final summary includes:
- Total records collected
- Successful connections
- Failed connections

## Example Output

```
SERVER01 - Reachable, retrieving scheduled tasks...
SERVER01 - Found 47 scheduled tasks
SERVER02 - Reachable, retrieving scheduled tasks...
SERVER02 - Found 52 scheduled tasks
SERVER03 - NOT reachable (ping failed)

========================================
File created successfully: C:\temp\Info_Task_Schedule_05-01-2026.csv
Total records: 99
Successful: 2 | Errors: 1
========================================
```

## Error Handling

The script handles various error scenarios:

- **Ping Failures**: Marks server as "Not reachable"
- **WinRM/Kerberos Errors**: Displays authentication error messages
- **Access Denied**: Indicates permission issues
- **Invalid OU Path**: Validates Active Directory paths
- **Missing Files**: Checks file existence before processing

Computers with errors are still included in the CSV output with appropriate error messages.

## Troubleshooting

### Common Issues

**1. WinRM/Kerberos Authentication Errors**
```powershell
# On the target computer, verify WinRM service is running
Get-Service WinRM

# Check WinRM configuration
winrm get winrm/config
```

**2. Access Denied**
- Ensure you have local admin rights on target computers
- Use the credential option with an account that has appropriate permissions
- Check firewall rules allow WinRM traffic (TCP 5985/5986)

**3. Active Directory Module Not Found**
```powershell
# Install RSAT tools on Windows 10/11
Add-WindowsCapability -Online -Name Rsat.ActiveDirectory.DS-LDS.Tools~~~~0.0.1.0

# Or download from Microsoft
```

**4. Script Execution Blocked**
```powershell
# Check current execution policy
Get-ExecutionPolicy

# Set execution policy (as Administrator)
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope LocalMachine
```

### Firewall Configuration

Ensure the following ports are open on target computers:
- **TCP 5985**: WinRM HTTP
- **TCP 5986**: WinRM HTTPS (if using SSL)
- **ICMP**: For ping connectivity tests

## Performance Considerations

- The script processes computers sequentially
- Typical execution time: 2-5 seconds per computer
- Large environments (100+ computers) may take several minutes
- Network latency affects overall performance

## Security Best Practices

1. **Use Least Privilege**: Run script with minimum required permissions
2. **Secure Credentials**: Use domain accounts rather than local admin where possible
3. **Audit Output**: Review exported CSV for sensitive information before sharing
4. **Clean Up**: Delete old CSV files containing sensitive data when no longer needed
5. **Log Retention**: CSV files contain usernames and task details - handle appropriately

## Version History

| Version | Date | Changes |
|---------|------|---------|
| 2.0 | January 2026 | Complete rewrite with credential support, improved error handling |
| 1.0 | - | Initial release |

## Author

**WeAreProject®**

## License

This script is provided as-is without warranty. Use at your own risk.

## Support

For issues, questions, or contributions:
- Review the troubleshooting section
- Check PowerShell execution policies
- Verify network connectivity and permissions
- Ensure WinRM is enabled on target systems

---

**Note**: This script requires PowerShell Remoting to be enabled on all target computers. Always test in a non-production environment first.
