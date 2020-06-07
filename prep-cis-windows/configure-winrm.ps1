Write-Output "Running User Data Script"
Write-Host "(host) Running User Data Script"

Set-ExecutionPolicy Unrestricted -Scope LocalMachine -Force -ErrorAction Ignore

# Don't set this before Set-ExecutionPolicy as it throws an error
$ErrorActionPreference = "stop"

cmd.exe /c winrm quickconfig -q

# Remove HTTP listener
Remove-Item -Path WSMan:\Localhost\listener\listener* -Recurse

# WinRM
Write-Output "Setting up WinRM"
Write-Host "(host) setting up WinRM"

Set-ItemProperty HKLM:\Software\Policies\Microsoft\Windows\WinRM\Service -name AllowBasic -Value 1
Set-ItemProperty HKLM:\Software\Policies\Microsoft\Windows\WinRM\Client -name AllowBasic -Value 1

Set-ItemProperty HKLM:\Software\Policies\Microsoft\Windows\WinRM\Service -name AllowUnencryptedTraffic -Value 1
Set-ItemProperty HKLM:\Software\Policies\Microsoft\Windows\WinRM\Client -name AllowUnencryptedTraffic -Value 1

New-NetFirewallRule -Direction Inbound -Action Allow -DisplayName "Windows Remote Management [HTTPS-In]" -Description "Inbound rule for Windows Remote Management via WS-Management. [TCP 5986]" -Program "System" -Profile Domain,Private -Protocol TCP -LocalPort "5986" -RemotePort Any

cmd.exe /c net stop winrm
cmd.exe /c sc config winrm start= auto
cmd.exe /c net start winrm

# Run Sysprep
& $env:SystemRoot\\System32\\Sysprep\\Sysprep.exe /oobe /generalize /quiet /quit /mode:vm
while($true) { $imageState = Get-ItemProperty HKLM:\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Setup\\State | Select ImageState; Write-Output $imageState.ImageState; if($imageState.ImageState -ne 'IMAGE_STATE_GENERALIZE_RESEAL_TO_OOBE') { Start-Sleep -s 10 } else { break } }