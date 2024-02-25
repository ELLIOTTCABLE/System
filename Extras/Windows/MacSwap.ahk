#SingleInstance force

SetCapsLockState("AlwaysOff")

#UseHook True
*7::+7
*5::+5
*3::+3
*1::+1
*9::+9
*0::+0
*2::+2
*4::+4
*6::+6
*8::+8

*+1::1
*+2::2
*+3::3
*+4::4
*+5::5
*+6::6
*+7::7
*+8::8
*+9::9
*+0::0
#UseHook False

; Remap a select set of Ctrl mods to make my muscle-memory happy with
; Ctrl/Cmd swapped:
#HotIf WinActive("ahk_exe code.exe") or WinActive("ahk_exe WindowsTerminal.exe")
#c::^c
#q::^q ; vi-mode column select
#HotIf
