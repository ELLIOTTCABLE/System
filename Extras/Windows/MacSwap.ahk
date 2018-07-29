#Include %A_LineFile%\..\Flirc.ahk

; "Windows" key? What's that shit?
; I've decided to use SharpKeys for this, instead:
;     <https://github.com/randyrants/sharpkeys>
; (See <https://www.autohotkey.com/docs/misc/Remap.htm#registry> for more raitonale.)
;RCtrl::RWin
;RWin::RCtrl
;LCtrl::LWin
;LWin::LCtrl
; ... except command-tab
;*Tab::Send {Blind}{Tab}


; vim-lover
; This particular implementation by "Oracle":
;     <https://autohotkey.com/board/topic/104173-capslock-to-control-and-escape/>
SetCapsLockState, AlwaysOff

; CapsLock::
; 	key=
; 	Input, key, B C L1 T1, {Esc}
; 	if (ErrorLevel = "Max")
; 		Send {Ctrl Down}%key%
; 	KeyWait, CapsLock
; 	Return
; CapsLock up::
; 	If key
; 		Send {Ctrl Up}
; 	else
; 		if (A_TimeSincePriorHotkey < 1000)
; 			Send, {Esc 2}
; 	Return


; Media-key replacements for my weird-ass keyboard
SetNumLockState, AlwaysOff
SC04F::Media_Play_Pause  	; 89, "Num1" - Top-left key on right thumbkeyboard
SC04B::Volume_Mute         ; 92, "Num4" - (shifted)
SC050::Volume_Down 			; 90, "Num2" - Top-second key on right thumbkeyboard
SC04C::Media_Prev        	; 93, "Num5" - (shifted)
SC051::Volume_Up       		; 91, "Num3" - Top-third key on right thumbkeyboard
SC04D::Media_Next          ; 94, "Num6" - (shifted)
