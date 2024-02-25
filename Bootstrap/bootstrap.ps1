
function Install-Package-Manager-Build-Deps {

}

function Install-Package-Manager {
   $URL = "https://api.github.com/repos/microsoft/winget-cli/releases/latest"
   $URL = (Invoke-WebRequest -Uri $URL).Content | ConvertFrom-Json |
         Select-Object -ExpandProperty "assets" |
         Where-Object "browser_download_url" -Match '.msixbundle' |
         Select-Object -ExpandProperty "browser_download_url"

   # Download
   Invoke-WebRequest -Uri $URL -OutFile "Setup.msix" -UseBasicParsing

   # Install
   Add-AppxPackage -Path "Setup.msix"

   # Delete file
   Remove-Item "Setup.msix"
}


Install-Package-Manager

# Frontload
winget install -e --id RandyRants.SharpKeys
winget install -e --id AgileBits.1Password.Beta
winget install -e --id Git.Git
winget install -e --id GitHub.cli
winget install -e --id GitHub.GitHubDesktop
winget install -e --id Logitech.OptionsPlus
winget install -e --id Mozilla.Firefox
winget install -e --id Microsoft.VisualStudioCode
winget install -e --id SyncTrayzor.SyncTrayzor
winget install -e --id Yubico.Authenticator
winget install -e --id Notion.Notion
winget install -e --id glzr-io.glazewm

# Next
winget install -e --id Valve.Steam
winget install -e --id RescueTime.DesktopApp
winget install -e --id Nvidia.GeForceExperience
winget install -e --id EpicGames.EpicGamesLauncher
winget install -e --id Ubisoft.Connect
winget install -e --id ElectronicArts.EADesktop

# Rest
winget install -e --id Armin2208.WindowsAutoNightMode
winget install -e --id AutoHotkey.AutoHotkey
winget install -e --id Discord.Discord
winget install -e --id FinalWire.AIDA64.Extreme
winget install -e --id Google.Chrome
winget install -e --id icsharpcode.ILSpy
winget install -e --id IPFS.IPFS-Desktop
winget install -e --id Microsoft.PowerToys
winget install -e --id Microsoft.VisualStudio.2022.Community
winget install -e --id NexusMods.Vortex
winget install -e --id OpenWhisperSystems.Signal
winget install -e --id SatisfactoryModding.SatisfactoryModManager
winget install -e --id SlackTechnologies.Slack
winget install -e --id Ubisoft.Connect
winget install -e --id VB-Audio.Voicemeeter.Banana
winget install -e --id AgileBits.1Password.CLI
winget install -e --id code52.Carnac

# TODO: User-level (non-admin)
winget install -e --id 9NCBCSZSJRSB # Spotify

# ## Setup GlazeWM
# Note that S4U: https://learn.microsoft.com/en-us/windows/win32/taskschd/principal-logontype#property-value
# "The user must log on using a service for user (S4U) logon."
$trigger = New-ScheduledTaskTrigger -AtLogon -User "$env:USERDOMAIN\$env:USERNAME"

$principal = New-ScheduledTaskPrincipal -UserId "$env:USERDOMAIN\$env:USERNAME" `
   -LogonType Interactive -RunLevel Highest

$settings = New-ScheduledTaskSettingsSet -ExecutionTimeLimit 0 `
   -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries

$action = New-ScheduledTaskAction `
   -Execute "$env:LOCALAPPDATA\Microsoft\WinGet\Packages\glzr-io.glazewm_Microsoft.Winget.Source_8wekyb3d8bbwe\glazewm.exe"

Register-ScheduledTask "GlazeWM" -Trigger $trigger -Principal $principal `
   -Settings $settings -Action $action
