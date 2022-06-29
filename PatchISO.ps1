$OSCDIMGFolder = ".\OSCDIMG"
$OSCDIMG = "$OSCDIMGFolder\oscdimg.exe" 
$ETFSBoot = "$OSCDIMGFolder\etfsboot.com" 
$EFISys = "$OSCDIMGFolder\efisys_noprompt.bin"

$SourceISOPath = "C:\Users\Colin\Desktop\Win10_21H2_English_x64.iso"
$ISOFilesFolder = ".\tmp" 
$AutounattendPath = ".\autounattend.xml"
$DestinationISOPath = ".\Win10_Unattended.iso"

Write-Host "Checking OSCDIMG files..." 

foreach ($Item in @($OSCDIMGFolder, $OSCDIMG, $ETFSBoot, $EFISys))
{
    if (! (Test-Path $Item))
    {
        Write-Error "$Item not found!"
        Exit
    }
}


Write-Host "Mounting ISO..."

Mount-DiskImage -ImagePath $SourceISOPath -StorageType ISO -PassThru -Verbose
$ISODriveLetter = (Get-DiskImage -ImagePath $SourceISOPath | Get-Volume).DriveLetter + ":"

Write-Host "Extracting ISO files..."

if (! (Test-Path $ISOFilesFolder)) { 
   New-Item -Type Directory -Path $ISOFilesFolder
}
Copy-Item $ISODriveLetter\* $ISOFilesFolder -Force -Recurse

Write-Host "Unmounting ISO..." 

Dismount-DiskImage -ImagePath $SourceISOPath -Verbose 

Write-Host "Removing read-only attributes..."

Get-ChildItem $ISOFilesFolder -Recurse | %{ if (! $_.psiscontainer) { $_.isreadonly = $false}}

Write-Host "Injecting autounattend.xml..."

Copy-Item $AutounattendPath $ISOFilesFolder

Write-Host "Creating patched ISO"

$BootData = '2#p0,e,b"{0}"#pEF,e,b"{1}"' -f $ETFSBoot, $EFISys
Start-Process $oscdimg -args @("-bootdata:$BootData",'-m', '-o', '-u2','-udfver102', $ISOFilesFolder, $DestinationISOPath) -Wait -NoNewWindow

Write-Host "Cleaning up ISO files..."

Remove-Item $ISOFilesFolder -Recurse -Force
