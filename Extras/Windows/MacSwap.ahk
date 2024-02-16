#SingleInstance force

SetCapsLockState("AlwaysOff")

; Unshift numrow on Ergodox(en)
; /via //www.autohotkey.com/board/topic/24015-invert-number-row-on-main-keyboard/?p=218201

#UseHook
*7::&
*5::Send("%")
*3::#
*1::!
*9::(
*0::)
*2::@
*4::$
*6::^
*8::*

$+1::Send(1)
$+2::Send(2)
$+3::Send(3)
$+4::Send(4)
$+5::Send(5)
$+6::Send(6)
$+7::Send(7)
$+8::Send(8)
$+9::Send(9)
$+0::Send(0)

!F4::SendPlay("!{F4}")
