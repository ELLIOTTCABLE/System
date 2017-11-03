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

CapsLock::
	key=
	Input, key, B C L1 T1, {Esc}
	if (ErrorLevel = "Max")
		Send {Ctrl Down}%key%
	KeyWait, CapsLock
	Return
CapsLock up::
	If key
		Send {Ctrl Up}
	else
		if (A_TimeSincePriorHotkey < 1000)
			Send, {Esc 2}
	Return


; Media-key replacements for my weird-ass keyboard
SetNumLockState, AlwaysOff
SC04C::Volume_Up        ; up-arrow to the right of F6
SC04D::return           ; ... shifted
SC047::Volume_Down      ; down-arrow to the right of 6
SC048::Volume_Mute      ; ... shifted

SC04F::Media_Prev       ; left-arrow to the right of F12
SC050::Media_Play_Pause ; ... shifted
SC051::Media_Next       ; right-arrow to the right of F12
SC04B::return           ; ... shifted
