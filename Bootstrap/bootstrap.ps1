function Test-Admin {
   $currentUser = New-Object Security.Principal.WindowsPrincipal $([Security.Principal.WindowsIdentity]::GetCurrent())
   $currentUser.IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)
}

if ((Test-Admin) -eq $false) {
   Write-Host "This script requires administrator privileges. Please run it as an administrator."
   exit
}

# Set the working directory to the script's grandparent directory
$grandparentDirectory = Split-Path -Parent -Path (Split-Path -Parent -Path $MyInvocation.MyCommand.Definition)
if ((Get-Location).Path -ne $grandparentDirectory) {
   Set-Location -Path $grandparentDirectory
   Write-Host "Changed directory to $grandparentDirectory"
}

# --- Everything below this line will be run as Administrator ---

# Create a "Task Scheduler" task to start GlazeWM at logon.
# Note: this appears to cause some sort of bug if you don't disable the
#    "system tray" plugin; see: <https://github.com/glzr-io/glazewm/issues/546>)
function Initialize-GlazeScheduledTask {
   $taskName = "GlazeWM"
   $existingTask = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue

   if ($null -eq $existingTask) {
      $trigger = New-ScheduledTaskTrigger -AtLogon -User "$env:USERDOMAIN\$env:USERNAME"

      $principal = New-ScheduledTaskPrincipal -UserId "$env:USERDOMAIN\$env:USERNAME" `
         -LogonType Interactive -RunLevel Highest

      $settings = New-ScheduledTaskSettingsSet -ExecutionTimeLimit 0 `
         -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries

      $action = New-ScheduledTaskAction `
         -Execute "$env:LOCALAPPDATA\Microsoft\WinGet\Packages\glzr-io.glazewm_Microsoft.Winget.Source_8wekyb3d8bbwe\glazewm.exe"

      Register-ScheduledTask $taskName -Trigger $trigger -Principal $principal `
         -Settings $settings -Action $action
   }
}

# TODO: implement git-hooks on Windows
# function Init-Hooks {
#    & "./Scripts/install-git-hooks.sh"
# }

# TODO: Create a single-source-of-truth for this list, so it can be shared with the
# Rakefile or macOS config or whatever
function Initialize-Submodules {
   & "git" "submodule" "update" "--init" "--recursive" "--jobs" "4"
   New-Item -ItemType Directory -Force -Path "$(Get-Location)/Dotfiles/vim/backup"
   New-Item -ItemType Directory -Force -Path "$(Get-Location)/Dotfiles/vim/undo"
   New-Item -ItemType Directory -Force -Path "$(Get-Location)/Dotfiles/ssh/sockets"
   New-Item -ItemType Directory -Force -Path "$(Get-Location)/Dotfiles/ssh/identities"
}

# TODO: Figure out if this is even needed on Windows ssh/gnupg?
# function Init-Dotfiles {
#    Init-Symlinks
#    & "icacls" "$((Get-Location)/Dotfiles/ssh)" "/grant:r" "*S-1-5-32-545:(OI)(CI)F"
#    & "icacls" "$((Get-Location)/Dotfiles/gnupg)" "/grant:r" "*S-1-5-32-545:(OI)(CI)F"
# }

function Initialize-Symlinks {
   $files = Get-ChildItem -Path "Dotfiles\*" -File
   $files += Get-ChildItem -Path "Dotfiles\*" -Directory
   Write-Host "Linking in $HOME\"
   foreach ($file in $files) {
      $from = $file.FullName
      $to = Join-Path -Path $HOME -ChildPath ("." + $file.Name)
      if (Test-Path -Path $to) {
         Write-Host "   ! $to exists... "
         if ((Get-Item -Path $to).LinkType) {
            (Get-Item -Path $to).Delete()
            Write-Host "as a symlink, removed"
         } else {
            Write-Host "as a normal file/directory, moving to $($file.Name)~... "
            $toto = $to + "~"
            if (Test-Path -Path $toto) {
               Write-Host "already exists! r)emove, or s)kip? "
               $order = Read-Host
               switch ($order) {
                  "r" {
                     Write-Host '   ! Removing... '
                     Remove-Item -Path $toto
                  }
                  "s" {
                     Write-Host '   ! Okay, skipped '
                     continue
                  }
                  default {
                     Write-Host "   ! Invalid entry, so skipping"
                     continue
                  }
               }
            }
            Move-Item -Path $to -Destination $toto
            Write-Host "Done!"
         }
      }
      New-Item -ItemType SymbolicLink -Path $to -Target $from
   }
}

Write-Host "== Initializing submodules..."
Initialize-Submodules
Write-Host "== Initializing symlinks..."
Initialize-Symlinks
Write-Host "== Initializing Glaze scheduled task..."
Initialize-GlazeScheduledTask
Write-Host "== Installing my frontload programs..."
& "$PSScriptRoot\frontload.ps1"
Write-Host "== Installing the rest of my programs..."
& "$PSScriptRoot\rest.ps1"
