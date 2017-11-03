NirCmd = %A_ProgramFiles%\nircmd-x64\nircmdc.exe
MMT = %A_ProgramFiles%\multimonitortool-x64\MultiMonitorTool.exe

^!0::
   ; Suspend on Ctrl-Alt-0
   suspendScript =
   (
      Add-Type -AssemblyName System.Windows.Forms;

      # 1. Define the power state you wish to set, from the
      #    System.Windows.Forms.PowerState enumeration.
      $PowerState = [System.Windows.Forms.PowerState]::Suspend;

      # 2. Choose whether or not to force the power state
      $Force = $false;

      # 3. Choose whether or not to disable wake capabilities
      $DisableWake = $false;

      # Set the power state
      [System.Windows.Forms.Application]::SetSuspendState($PowerState, $Force, $DisableWake);
   )

   ;RunWait PowerShell.exe -Command &{%suspendScript%},, hide

   ; use this call if you want to see powershell output
   Run PowerShell.exe -NoExit -Command &{%suspendScript%}
Return


SetKVMVideo:
   RunWait, %MMT% /enable 1 /SetPrimary 1 /MoveWindow 1 All
   SetTimer, SetKVMVideoFixWindows, 2500
Return
SetKVMVideoFixWindows:
   Run, %MMT%  /MoveWindow 1 All ; Yes, these are duplicated intentionally
Return

SetTVVideo:
   RunWait, %MMT% /enable 2 /SetPrimary 2 /MoveWindow 2 All
   SetTimer, SetTVVideoFixWindows, 2500
Return
SetTVVideoFixWindows:
   Run, %MMT% /MoveWindow 2 All ; Yes, these are duplicated intentionally
Return

SetKVMAudio:
   Run, %NirCmd% setdefaultsounddevice "KVM"
Return

SetTVAudio:
   Run, %NirCmd% setdefaultsounddevice "irDAC"
Return

SetViveAudio:
   Run, %NirCmd% setdefaultsounddevice "VIVE USB Headphones"
Return

OpenVR:
   Progress, 0
   IfWinNotExist, ahk_exe vrmonitor.exe
      Run, "steam://rungameid/250820"
   Progress, 10

   WinWait, ahk_exe vrmonitor.exe
   WinMove, 25, 25
   Progress, 25

   Gosub, OpenVRMirror
   Progress, 90

   ; Dirty fuckin' hack.
   WinWait, ahk_exe Htc.Identity.Authenticator.exe,, 5
   WinClose
   Progress, 100

   Sleep, 500
   Progress, OFF
Return

OpenVRMirror:
   IfWinNotExist, ahk_exe vrcompositor.exe
   {
      WinWait, ahk_exe vrmonitor.exe
      Progress, 50
      Sleep, 1000
      Progress, 65
      ControlClick, X25 Y25,,, LEFT,, NA X25 Y25 ; "SteamVR" window header
      Loop, 3
         ControlSend, ahk_parent, {Down}
      ControlSend, ahk_parent, {Enter}
      Progress, 75
   }
   WinWait, ahk_exe vrcompositor.exe
   WinMaximize
Return


ExitVR:
   Progress, 0
   Sleep, 50 ; WHYYYYYYY

   ControlClick, X25 Y25, ahk_exe vrmonitor.exe,, LEFT,, NA X25 Y25
   ControlSend, ahk_parent, {Up}, ahk_exe vrmonitor.exe
   ControlSend, ahk_parent, {Enter}, ahk_exe vrmonitor.exe
   Progress, 25

   ; Handle "... will also shut down 'blah'." notification
   WinWait, SteamVR Shutdown,, 1
   Progress, 50

   IfWinExist, SteamVR Shutdown
   {
      ControlClick, X275 Y275,,, LEFT,, NA X275 Y275 ; "OK"
   }
   Progress, 75

   WinWaitClose, ahk_exe vrmonitor.exe,, 10
   Progress, 100

   Sleep, 500
   Progress, OFF
Return

^!1:: ; Flirc: "Input HDMI1"
   Gosub, SetKVMVideo
   Gosub, SetKVMAudio
Return

^!2:: ; Flirc: "Input HDMI2"
^!8:: ; Flirc: "TV"
   Gosub, SetTVVideo
   Gosub, SetTVAudio
Return

^!7:: ; Flirc: "3D", to open VR
   Gosub, SetViveAudio
   Gosub, OpenVR
Return

^!9:: ; Flirc: "Game", to exit VR
  ;Gosub, SetKVMVideo ; hmm.
   Gosub, SetKVMAudio
   Gosub, ExitVR
Return
