; "Windows" key? What's that shit?
RCtrl::RWin
RWin::RCtrl
LCtrl::LWin
LWin::LCtrl

; vim-lover
Capslock::Esc

; completions
::ddis::
   PutUni("ಠ_ಠ")
   Return

;Paste UTF8 string (Hex encoded or not) as unicode.
;If you don't use Hex encoding, you must save your script as UTF8
PutUni(DataIn)
{
   SavedClip := ClipBoardAll
   ClipBoard =
   If RegExMatch(DataIn, "^[0-9a-fA-F]+$")
   {
      Loop % StrLen(DataIn) / 2
         UTF8Code .= Chr("0x" . SubStr(DataIn, A_Index * 2 - 1, 2))
   }
   Else
      UTF8Code := DataIn
   Transform, ClipBoard, Unicode, %UTF8Code%
   Send ^v
   Sleep 100 ;Generous, less wait or none will often work.
   ClipBoard := SavedClip
   return
}
