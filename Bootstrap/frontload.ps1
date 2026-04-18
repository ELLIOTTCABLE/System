# Ensure that Git installs in such a way as to include `git.exe` in the WSL $PATH.
# See: <https://gitforwindows.org/silent-or-unattended-installation.html>
winget install -e --id Git.Git --custom "/o:PathOption=Cmd"

winget install -e --id RandyRants.SharpKeys
winget install -e --id AgileBits.1Password.Beta
winget install -e --id GitHub.cli
winget install -e --id GitHub.GitHubDesktop
winget install -e --id Logitech.OptionsPlus
winget install -e --id Mozilla.Firefox
winget install -e --id Microsoft.VisualStudioCode
winget install -e --id SyncTrayzor.SyncTrayzor
winget install -e --id Yubico.Authenticator
winget install -e --id Notion.Notion
winget install -e --id glzr-io.glazewm
