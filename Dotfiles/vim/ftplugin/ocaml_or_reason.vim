if &rtp =~ 'merlin'
   map <silent> <buffer> <LocalLeader>*  <Plug>(MerlinSearchOccurrencesForward)
   map <silent> <buffer> <LocalLeader>#  <Plug>(MerlinSearchOccurrencesBackward)
   map <silent> <buffer> <LocalLeader>r  <Plug>(MerlinRename)
   map <silent> <buffer> <LocalLeader>R  <Plug>(MerlinRenameAppend)

   " I don't know why Merlin doesn't ship with a mapping for these.
   map <silent> <buffer> <LocalLeader>y  <C-u>:MerlinYankLatestType<cr>
   map <silent> <buffer> <LocalLeader>l  <C-u>:MerlinLocate<cr>

   map <silent> <buffer> <LocalLeader>o  <C-u>:Denite documentSymbol -mode=normal<cr>

   " FIXME: Report these; they should support buffer-local settings as well as global ones
   let g:merlin_textobject_grow   = 'm'
   let g:merlin_textobject_shrink = 'M'

   call merlin#Register()
endif

if g:use_languageclient
   LanguageClientStart
endif

" REPORTME: It looks like Merlin's omnifunc is broken with Deoplete? I'm using
"	       `copy/deoplete-ocaml` instead, so.
"au FileType ocaml set omnifunc<
