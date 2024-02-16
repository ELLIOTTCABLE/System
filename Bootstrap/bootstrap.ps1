
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

winget install -e --id Armin2208.WindowsAutoNightMode
winget install -e --id AutoHotkey.AutoHotkey
winget install -e --id Discord.Discord
winget install -e --id EpicGames.EpicGamesLauncher
winget install -e --id FinalWire.AIDA64.Extreme
winget install -e --id Git.Git
winget install -e --id GitHub.cli
winget install -e --id GitHub.GitHubDesktop
winget install -e --id Google.Chrome
winget install -e --id icsharpcode.ILSpy
winget install -e --id IPFS.IPFS-Desktop
winget install -e --id Logitech.OptionsPlus
winget install -e --id Microsoft.PowerToys
winget install -e --id Microsoft.VisualStudio.2022.Community
winget install -e --id Microsoft.VisualStudioCode
winget install -e --id Mozilla.Firefox
winget install -e --id NexusMods.Vortex
winget install -e --id Notion.Notion
winget install -e --id Nvidia.GeForceExperience
winget install -e --id OpenWhisperSystems.Signal
winget install -e --id OpenWhisperSystems.Signal
winget install -e --id RescueTime.DesktopApp
winget install -e --id SatisfactoryModding.SatisfactoryModManager
winget install -e --id SlackTechnologies.Slack
winget install -e --id Spotify.Spotify
winget install -e --id Spotify.Spotify
winget install -e --id SyncTrayzor.SyncTrayzor
winget install -e --id Ubisoft.Connect
winget install -e --id VB-Audio.Voicemeeter.Banana
winget install -e --id Yubico.Authenticator

winget install -e --id 9PBLBM45RJQJ # Harvest Time Tracker
