" FIXME: Ugh, why is this global ...
let g:localleader_key_map.t = { 'name':  '+type' }
let g:localleader_key_map.f = { 'name':  '+find' }

" Enable ocaml/vim-ocaml's foldmethod integration
let g:ocaml_folding=1
set nofoldenable

let g:merlin_disable_default_keybindings = v:true

if &rtp =~ 'merlin'
   map  <silent> <buffer> <LocalLeader>*  <Plug>(MerlinSearchOccurrencesForward)
   map  <silent> <buffer> <LocalLeader>#  <Plug>(MerlinSearchOccurrencesBackward)
   map  <silent> <buffer> <LocalLeader>r  <Plug>(MerlinRename)
   map  <silent> <buffer> <LocalLeader>R  <Plug>(MerlinRenameAppend)
   let g:localleader_key_map['*'] = 'ident-forward'
   let g:localleader_key_map['#'] = 'ident-backward'
   let g:localleader_key_map['r'] = 'ident-rename'
   let g:localleader_key_map['R'] = 'ident-append'

   map  <silent><buffer> <LocalLeader>tt :MerlinTypeOf<return>
   vmap <silent><buffer> <LocalLeader>tt :MerlinTypeOfSel<return>
   let g:localleader_key_map.t.t = 'type-info'

   map  <silent><buffer> <LocalLeader>tc :MerlinErrorCheck<return>
   let g:localleader_key_map.t.c = 'type-check'

   " I don't know why Merlin doesn't ship with a mapping for these.
   map  <silent> <buffer> <LocalLeader>ty <C-u>:MerlinYankLatestType<cr>
   let g:localleader_key_map.t.y = 'type-yank'

   map  <silent> <buffer> <LocalLeader>td <C-u>:MerlinDestruct<cr>
   let g:localleader_key_map.t.d = 'type-destruct'

   map  <silent><buffer> <LocalLeader>n :MerlinGrowEnclosing<return>
   map  <silent><buffer> <LocalLeader>p :MerlinShrinkEnclosing<return>
   let g:localleader_key_map.n = 'merlin-grow'
   let g:localleader_key_map.p = 'merlin-shrink'

   " FIXME: This is still broken, I think.
   map <silent> <buffer> <LocalLeader>o  <C-u>:Denite documentSymbol -mode=normal<cr>
   let g:localleader_key_map.f.o = 'find-symbol'


   " Non-<LocalLeader>-mapped bindings. Am I okay with these?
   vmap <silent><buffer> <Tab>   :<C-u>MerlinPhrase<return>

   map  <silent> <buffer> gd     :<C-u>MerlinLocate<cr>
   nmap <silent> <buffer> [[     :<C-u>MerlinPhrasePrev<cr>
   nmap <silent> <buffer> ]]     :<C-u>MerlinPhraseNext<cr>

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
