Write-Host "Installing VMware Tools..."

for ($letter = 0; $letter -lt 26; $letter++)
{
    $VMwareSetupFile = [char](65 + $letter) + ":\VMware_Tools_Setup.exe";
    
    if (Test-Path -Path $VMwareSetupFile)
    {
        break;
    }
}

Start-Process -FilePath $VMwareSetupFile -ArgumentList @("/S", "/v", '"/qn REBOOT=R ADDLOCAL=ALL"') -Wait

# Change power plan
powercfg -setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c
powercfg -change standby-timeout-ac 0
powercfg -change disk-timeout-ac 0
powercfg -change monitor-timeout-ac 0
powercfg -change hibernate-timeout-ac 0

# Set network profile to private
$NetworkProfile = Get-NetConnectionProfile
Set-NetConnectionProfile -Name $NetworkProfile.Name -NetworkCategory Private

# Install Chocolatey
Set-ExecutionPolicy Bypass -Scope Process -Force
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))

# Required Chocolatey packages
$Packages = @("7zip.install", "firefox", "googlechrome")

foreach ($Package in $Packages) {
    choco install $Package -y --ignore-checksums
}

# Install Nuget PackageProvider
Get-PackageProvider -Name NuGet -Force

# Install WindowsUpdate Module
if (-Not (Get-Module -ListAvailable -Name PSWindowsUpdate)) {
    Write-Host "Install WindowsUpdate Module"
    Install-Module PSWindowsUpdate -Confirm:$false -Force | Out-Null
}

Write-Host "Updating help files..."
Update-Help

# Check is busy
while ((Get-WUInstallerStatus).IsBusy) {
    Write-Host "Windows Update installer is busy, wait..."
    Start-Sleep -s 10
}

# Install available Windows Updates
Write-Host "Start installation system updates..."
Install-WindowsUpdate -MaxSize 1073741824 -MicrosoftUpdate -AcceptAll -AutoReboot
