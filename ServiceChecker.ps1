
<# 
    Service Monitor & Enforcer
    - Reads desired service states from Services.csv (Name,Status)
    - Checks current status; if not desired, attempts to change it
    - Logs actions and results under .\Logs\

    NOTE: Starting/stopping services generally requires Administrator.
#>

# --- Paths (robust relative resolution) ---
$ScriptRoot = if ($PSScriptRoot) { $PSScriptRoot } else { (Get-Location).Path }

# CSV lives next to the script
$ServicesFilePath = [System.IO.Path]::GetFullPath('.\Services.csv', $ScriptRoot)

# Logs folder lives next to the script
$LogDir  = [System.IO.Path]::GetFullPath('.\Logs', $ScriptRoot)
if (-not (Test-Path $LogDir)) { New-Item -Path $LogDir -ItemType Directory | Out-Null }

# Timestamped log file (24h clock to avoid AM/PM ambiguity)
$LogFile = Join-Path $LogDir ("Services-{0}.log" -f (Get-Date -Format 'yyyy-MM-dd_HH-mm'))

# --- Load CSV ---
$ServicesList = Import-Csv -Path $ServicesFilePath -Delimiter ','

# --- Processing ---
foreach ($Service in $ServicesList) {
    try {
        # Read current status
        $svc = Get-Service -Name $Service.Name -ErrorAction Stop
        $CurrentServiceStatus = $svc.Status

        if ($Service.Status -ne $CurrentServiceStatus) {
            $log = "Service: {0} is currently {1}, should be {2}" -f $Service.Name, $CurrentServiceStatus, $Service.Status
            Write-Output $log
            Out-File -FilePath $LogFile -Append -InputObject $log

            $log = "Setting {0} to {1}" -f $Service.Name, $Service.Status
            Write-Output $log
            Out-File -FilePath $LogFile -Append -InputObject $log

            # Change state (use Start/Stop; Set-Service does not change running state)
            if ($Service.Status -eq 'Running') {
                Start-Service -Name $Service.Name -ErrorAction Stop
            } elseif ($Service.Status -eq 'Stopped') {
                Stop-Service -Name $Service.Name -ErrorAction Stop
            } else {
                # If CSV contains an unexpected status, note it and skip
                $log = "Unsupported desired status '{0}' for service {1}. Skipping." -f $Service.Status, $Service.Name
                Write-Output $log
                Out-File -FilePath $LogFile -Append -InputObject $log
                continue
            }

            # Verify
            $AfterActionStatus = (Get-Service -Name $Service.Name -ErrorAction Stop).Status
            if ($Service.Status -eq $AfterActionStatus) {
                $log = "Action successful. Service {0} is now {1}" -f $Service.Name, $AfterActionStatus
            } else {
                $log = "Action FAILED. Service {0} is still {1}" -f $Service.Name, $AfterActionStatus
            }
            Write-Output $log
            Out-File -FilePath $LogFile -Append -InputObject $log
        }
        # else: already in desired state; no log line to keep noise low
    }
    catch {
        $err = "ERROR handling service {0}: {1}" -f $Service.Name, $_.Exception.Message
        Write-Output $err
        Out-File -FilePath $LogFile -Append -InputObject $err
    }
}
