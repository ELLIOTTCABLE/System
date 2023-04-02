#SingleInstance force

SetCapsLockState("AlwaysOff")

; Unshift numrow on Ergodox(en)
#UseHook
*1::+1
*2::+2
*3::+3
*4::+4
*5::+5
*6::+6
*7::+7
*8::+8
*9::+9
*0::+0

*+1::
{
   Send("{Blind}{Shift Up}")
   Send("{Blind}1")
   Send("{Blind}{Shift Down}")
   return
}
*+2::
{
   Send("{Blind}{Shift Up}")
   Send("{Blind}2")
   Send("{Blind}{Shift Down}")
   return
}
*+3::
{
   Send("{Blind}{Shift Up}")
   Send("{Blind}3")
   Send("{Blind}{Shift Down}")
   return
}
*+4::
{
   Send("{Blind}{Shift Up}")
   Send("{Blind}4")
   Send("{Blind}{Shift Down}")
   return
}
*+5::
{
   Send("{Blind}{Shift Up}")
   Send("{Blind}5")
   Send("{Blind}{Shift Down}")
   return
}
*+6::
{
   Send("{Blind}{Shift Up}")
   Send("{Blind}6")
   Send("{Blind}{Shift Down}")
   return
}
*+7::
{
   Send("{Blind}{Shift Up}")
   Send("{Blind}7")
   Send("{Blind}{Shift Down}")
   return
}
*+8::
{
   Send("{Blind}{Shift Up}")
   Send("{Blind}8")
   Send("{Blind}{Shift Down}")
   return
}
*+9::
{
   Send("{Blind}{Shift Up}")
   Send("{Blind}9")
   Send("{Blind}{Shift Down}")
   return
}
*+0::
{
   Send("{Blind}{Shift Up}")
   Send("{Blind}0")
   Send("{Blind}{Shift Down}")
   return
}