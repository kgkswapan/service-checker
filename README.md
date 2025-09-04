# Service Monitor

A PowerShell script to monitor and enforce Windows service states.  
Reads a CSV with service names and desired states (Running/Stopped),  
attempts to correct mismatches, and logs results in the `Logs` folder.

## How it works
- Load service list from `Services.csv` (Name,Status)
- Check current status of each service
- If status differs, attempt to Start or Stop the service
- Log every action and result to a timestamped log file under `Logs`

## Example CSV
```csv
Name,Status
Spooler,Running
wuauserv,Stopped
``` 

## Run
```powershell
# Run the script (requires Administrator privileges)
.\ServiceMonitor.ps1
```

## License
MIT