#SingleInstance Force

SetCapsLockState("AlwaysOff")

#UseHook True
*7::Send("{Blind}+7")
*5::Send("{Blind}+5")
*3::Send("{Blind}+3")
*1::Send("{Blind}+1")
*9::Send("{Blind}+9")
*0::Send("{Blind}+0")
*2::Send("{Blind}+2")
*4::Send("{Blind}+4")
*6::Send("{Blind}+6")
*8::Send("{Blind}+8")

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
#c::Send("^c")
#q::Send("^q") ; vi-mode column select
#HotIf
