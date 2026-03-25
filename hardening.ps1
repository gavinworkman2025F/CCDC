param(
    [Parameter(Mandatory=$true)]
    [string]$NewPassword,

    [Parameter(Mandatory=$true)]
    [string]$Username,

    [Parameter(Mandatory=$true)]
    [string]$CurrentPassword
)

# ================================
# Elevation Check
# ================================
$identity = [Security.Principal.WindowsIdentity]::GetCurrent()
$principal = New-Object Security.Principal.WindowsPrincipal($identity)

if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "[+] Relaunching as Administrator..."
    Start-Process powershell -ArgumentList "-ExecutionPolicy Bypass -File `"$PSCommandPath`" -NewPassword `"$NewPassword`" -Username `"$Username`" -CurrentPassword `"$CurrentPassword`"" -Verb RunAs
    exit
}

# ================================
# Setup
# ================================
$LogDir = "C:\Temp\hardening_logs"
$Timestamp = Get-Date -Format "yyyyMMdd_HHmmss"

New-Item -ItemType Directory -Force -Path $LogDir | Out-Null

Write-Host "[+] Starting Windows hardening..."

# ================================
# 1. Ensure Admin User Exists
# ================================
Write-Host "[+] Ensuring admin user exists..."

if (-not (Get-LocalUser -Name $Username -ErrorAction SilentlyContinue)) {
    Write-Host "[*] Creating user $Username"
    net user $Username $NewPassword /add
}

# Add to Administrators group
net localgroup administrators $Username /add

# Set password
net user $Username $NewPassword

# ================================
# 2. Reset Local Administrator Password
# ================================
Write-Host "[+] Resetting local Administrator password..."
net user Administrator $NewPassword

# ================================
# 3. Enumerate Admins & Sessions
# ================================
Write-Host "[+] Enumerating administrators..."
net localgroup administrators | Out-File "$LogDir\admins_$Timestamp.txt"

Write-Host "[+] Active sessions..."
qwinsta | Out-File "$LogDir\sessions_$Timestamp.txt"

# ================================
# 4. Enable Firewall
# ================================
Write-Host "[+] Enabling Windows Firewall..."
netsh advfirewall set allprofiles state on

# Optional: Block inbound except allowed (be careful)
# netsh advfirewall firewall set rule group="remote desktop" new enable=yes

# ================================
# 5. Apply Security Policy (secedit)
# ================================
Write-Host "[+] Exporting current security policy..."
secedit /export /cfg "$LogDir\current_sec_$Timestamp.inf"

# Create hardened config
$SecConfig = @"
[System Access]
MinimumPasswordLength = 12
PasswordComplexity = 1

[Event Audit]
AuditLogonEvents = 3
AuditAccountManage = 3
AuditProcessTracking = 1

[Registry Values]
MACHINE\System\CurrentControlSet\Control\Lsa\LmCompatibilityLevel=4,5
MACHINE\System\CurrentControlSet\Control\Lsa\NoLMHash=4,1
MACHINE\System\CurrentControlSet\Control\Lsa\RestrictAnonymous=4,1
MACHINE\System\CurrentControlSet\Control\Lsa\RestrictAnonymousSAM=4,1
"@

$SecFile = "$LogDir\hardened_$Timestamp.inf"
$SecConfig | Out-File $SecFile -Encoding ASCII

Write-Host "[+] Applying security policy..."
secedit /configure /db secedit.sdb /cfg $SecFile /quiet

# ================================
# 6. Disable Teredo
# ================================
Write-Host "[+] Disabling Teredo..."
netsh interface teredo set state disabled

# ================================
# 7. Persistence Checks
# ================================
Write-Host "[+] Checking persistence mechanisms..."

# Registry Run keys
reg query HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Run > "$LogDir\run_keys_$Timestamp.txt"

# Scheduled Tasks
schtasks /query /fo LIST /v > "$LogDir\tasks_$Timestamp.txt"

# Services
Get-Service | Where-Object {$_.Status -eq "Running"} | Out-File "$LogDir\services_$Timestamp.txt"

# Processes
Get-Process | Sort-Object CPU -Descending | Out-File "$LogDir\processes_$Timestamp.txt"

# Suspicious Notepad check
Get-Process notepad -ErrorAction SilentlyContinue | Out-File "$LogDir\notepad_check_$Timestamp.txt"

# ================================
# 8. Defender (if available)
# ================================
if (Get-Command "Set-MpPreference" -ErrorAction SilentlyContinue) {
    Write-Host "[+] Enabling Windows Defender protections..."
    Set-MpPreference -DisableRealtimeMonitoring $false
}

# ================================
# 9. Summary
# ================================
Write-Host "[+] Hardening complete."
Write-Host "[+] Admin user: $Username"
Write-Host "[+] Logs stored at: $LogDir"
Write-Host "[!] ACTIONS REQUIRED:"
Write-Host "    - Review admins group"
Write-Host "    - Review scheduled tasks and services"
Write-Host "    - Run Autoruns (Sysinternals) manually"