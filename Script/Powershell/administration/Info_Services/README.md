# Info_Services.ps1

**Description**
- Interactive PowerShell script to collect Windows service information from multiple remote computers and export the results to a CSV file.

**Requirements**
- PowerShell 5.1 or newer (PowerShell Core/7+ compatible).
- For the Active Directory option: the `ActiveDirectory` module (for example, RSAT installed on Windows).
- Appropriate permissions and credentials for remote access to target computers (DCOM/RPC or WinRM configured).

**Key Features**
- Load a list of computers from a text file.
- Load computers from an Active Directory OU.
- Support for remote credentials via `Get-Credential`.
- Connection attempts in order: DCOM with credentials -> DCOM without credentials -> WinRM.
- Exports results to CSV using `;` delimiter (UTF-8) in `C:\temp\`.

**Script location**
- File: Script/Powershell/administration/Info_Services/Info_Services.ps1

**Usage**
1. Run the script in a PowerShell session with appropriate privileges:

```powershell
.\Info_Services.ps1
```

2. Choose an option from the interactive menu:
- `1` — Load computers from a file (one hostname per line).
- `2` — Load computers from an Active Directory OU (enter the OU DistinguishedName).
- `Q` — Quit.

3. When prompted, choose whether to use specific credentials (`Y`) or the current user context (`N`).

**Input file format (option 1)**
- Plain text file with one hostname per line and no header.
- Example:

```
server01
server02
workstation05
```

**Output**
- CSV file created in `C:\temp\` named `Info_Services_dd-MM-yyyy.csv`.
- Exported columns: `ServerName`, `StartName`, `State`, `DisplayName`, `StartMode`.
- Delimiter: `;` (semicolon).

**Example run**
- To load from `C:\lists\servers.txt`: select `1`, enter the full file path when prompted, then answer `Y` or `N` for credentials. The CSV will be created in `C:\temp\`.

**Notes & Troubleshooting**
- Ensure RPC/DCOM or WinRM is reachable and that firewall ports are not blocked.
- If you encounter authentication errors, try running the script with a domain account that has appropriate privileges.
- For the AD option, install RSAT or run the script from a domain-joined management host where the `ActiveDirectory` module is available.

**Author**
- Gianluca Matera

**License**
- See the `LICENSE` file at the repository root.
