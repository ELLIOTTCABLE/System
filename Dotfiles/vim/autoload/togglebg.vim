" NOTE: Intentionally using the same name as Solarized's version, so they don't stomp on oneanother.
if exists('g:loaded_togglebg') || &cp || v:version < 700
  finish
endif
let g:loaded_togglebg = v:true

let s:cpo_save = &cpo
set cpo&vim


" NOTE: I really would rather use xolox#misc#msg#debug, but ... requiring the user to install
"       vim-misc just for that? Meh.
function! s:debug(msg)
   if &vbs >= 1
      echom a:msg
   endif
endfunction

function! s:init()
   if !exists("no_plugin_maps") && !hasmapto('<Plug>ToggleBackground')
      call togglebg#map("<F5>")
   endif
endfunction

if !exists("g:togglebg_define_commands") || g:togglebg_define_commands
   command! -bar -nargs=* -complete=custom,<SID>complete_background ToggleBackground
       \ call togglebg#(<f-args>)
   command! -bar -nargs=1 -complete=color SafeColorscheme
       \ call togglebg#colorscheme(<f-args>)
   command! -nargs=1 -complete=custom,s:complete_lightline_colorschemes LightlineColorscheme
         \ call togglebg#lightline_colorscheme(<q-args>)
   if exists(':Bg') ==# 2
      command! -bar -nargs=* -complete=custom,<SID>complete_background Bg
          \ call togglebg#(<f-args>)
   endif

   call s:debug("Defined togglebg commands")
endif

" Again, intentionally using Solarized's mappings
if !exists("g:togglebg_define_mapping") || g:togglebg_define_mapping
   nnoremap <unique> <script> <Plug>ToggleBackground <SID>togglebg
   inoremap <unique> <script> <Plug>ToggleBackground <C-\><C-n><SID>togglebg<C-\><C-n>a
   vnoremap <unique> <script> <Plug>ToggleBackground <C-\><C-n><SID>togglebg<C-\><C-n>gv

   noremap <SID>togglebg  :call togglebg#()<CR>

   call s:debug("Defined <Plug>ToggleBackground mapping")
endif

" Consider this deprecated. I'm only copying it to make transition easier — but it's rather
" purposeless, given that you can just use the map-commands yourself.
function! togglebg#map(activation)
   try
      exe "silent! nmap <unique> ".a:activation." <Plug>ToggleBackground"
      exe "silent! imap <unique> ".a:activation." <Plug>ToggleBackground"
      exe "silent! vmap <unique> ".a:activation." <Plug>ToggleBackground"

      call s:debug("Mapped " . a:activation . "to <Plug>ToggleBackground!")
   finally
      return 0
   endtry
endfunction


" Toggle `background`, either reloading the current colorscheme, or switching to a different one,
" in the process.
"
" If a mapping exists at `g:colorschemes`, then `g:colorschemes.light` will be used as the name of a
" colorscheme to activate after changing `background` to `'light'`; and vice versa for
" `g:colorschemes.dark`.
"
" Further, if Lightline is installed and enabled, and a mapping exists at
" `g:colorschemes.lightline`, then `g:colourschemes.lightline.dark` and `...light` will be used
" (with similar semantics) when toggling the background.
"
" With no arguments, simply toggles; can be given either `'dark'` or `'light'` as the first
" argument, dictating which background to switch to; can be given a colorscheme-name as the second
" argument, to switch to a specific theme after changing the background; and can be given a
" lightline-specific colorscheme-name as a third argument, with the same semantics.
function! togglebg#(...)
   " First, decide on a target `background` setting.
   if a:0 >=# 1 && len(a:1) !=# 0
      let l:background = a:1
   elseif &background ==? 'light'
      let l:background = 'dark'
   elseif &background ==? 'dark'
      let l:background = 'light'
   endif


   " I evaluate this early to take advantage of Vim's own error-message if the first argument is
   " insensible
   let &background = l:background
   call s:debug("Set background: " . l:background)

   let g:ayucolor = l:background
   call s:debug("Set ayucolor: " . l:background)

   " Now, we decide on a theme to set. If `g:colorschemes` is set to a dict, then we choose a
   " colorscheme depending on the new value of `background`; else, we simply re-load the current
   " colorscheme.
   if a:0 >=# 2 && len(a:2) !=# 0
      let l:colorscheme = a:2

   elseif l:background ==? 'light' && exists("g:colorschemes.light")
            \ && type(g:colorschemes.light) ==# type('')
      let l:colorscheme = g:colorschemes.light
   elseif l:background ==? 'dark' && exists("g:colorschemes.dark")
            \ && type(g:colorschemes.dark) ==# type('')
      let l:colorscheme = g:colorschemes.dark

   elseif exists('g:colors_name')
      let l:colorscheme = g:colors_name
   else
      let l:colorscheme = 'default'
   endif

   " Finally, we decide on a colorscheme for Lightline, if the configuration-dictionary exists.
   if exists('g:lightline')
      if a:0 >=# 3 && len(a:3) !=# 0
         let l:lightline_colorscheme = a:3

      elseif l:background ==? 'light' && exists("g:colorschemes.lightline.light")
               \ && type(g:colorschemes.lightline.light) ==# type('')
         let l:lightline_colorscheme = g:colorschemes.lightline.light
      elseif l:background ==? 'dark' && exists("g:colorschemes.lightline.dark")
               \ && type(g:colorschemes.lightline.dark) ==# type('')
         let l:lightline_colorscheme = g:colorschemes.lightline.dark

      elseif exists('g:colors_name')
         let l:lightline_colorscheme = g:colors_name
      else
         let l:lightline_colorscheme = 'default'
      endif

      call togglebg#colorscheme(l:colorscheme, l:lightline_colorscheme)
   else
      call togglebg#colorscheme(l:colorscheme)
   endif

endfunction

" The format of this callback is dictated by the documentation for `command-completion-custom`.
function! s:complete_background(ArgLead, CmdLine, CursorPos)
   return join(["dark", "light"], "\n")
endfunction

function! s:complete_lightline_colorschemes(...) abort
   return join(map(
         \ globpath(&rtp,"autoload/lightline/colorscheme/*.vim",1,1),
         \ "fnamemodify(v:val,':t:r')"),
         \ "\n")
endfunction


" These functions were written by Austin Smith (@auwsmit):
"    <https://github.com/altercation/solarized/issues/102#issuecomment-275269574>
"
" They allow for the 'safe' swapping of colorschemes that add language-specific highlight-groups.
function! togglebg#colorscheme(colo_name, ...)
   call <SID>find_links()
   exec "colorscheme " . a:colo_name
   call <SID>restore_links()

   call s:debug("Set colorscheme: " . a:colo_name)

   if a:0 >=# 1 && len(a:1) !=# 0
      call togglebg#lightline_colorscheme(a:1)
   endif
endfunction

" This is from the Lightline.vim docs
"    <https://github.com/itchyny/lightline.vim/blob/f4fa096a/doc/lightline.txt#L1220-L1267>
function! togglebg#lightline_colorscheme(ll_colo_name) abort
   if exists('g:lightline')
      let g:lightline.colorscheme = a:ll_colo_name

      if exists('#lightline')
         call lightline#init()
         call lightline#colorscheme()
         call lightline#update()
      endif

      call s:debug("Set lightline colorscheme: " . a:ll_colo_name)
   endif
endfunction

if !exists('s:known_links')
   let s:known_links = {}
endif

function! s:find_links() " {{{1
   " Find and remember links between highlighting groups.
   redir => listing
   try
      silent highlight
   finally
      redir END
   endtry

   for line in split(listing, "\n")
      let tokens = split(line)
      " We're looking for lines like "String xxx links to Constant" in the
      " output of the :highlight command.
      if len(tokens) == 5 && tokens[1] == 'xxx' && tokens[2] == 'links' && tokens[3] == 'to'
         let fromgroup = tokens[0]
         let togroup = tokens[4]
         let s:known_links[fromgroup] = togroup
      endif
   endfor
endfunction

function! s:restore_links() " {{{1
   " Restore broken links between highlighting groups.
   redir => listing
   try
      silent highlight
   finally
      redir END
   endtry
   let num_restored = 0
   for line in split(listing, "\n")
      let tokens = split(line)
      " We're looking for lines like "String xxx cleared" in the
      " output of the :highlight command.
      if len(tokens) == 3 && tokens[1] == 'xxx' && tokens[2] == 'cleared'
         let fromgroup = tokens[0]
         let togroup = get(s:known_links, fromgroup, '')
         if !empty(togroup)
            execute 'hi link' fromgroup togroup
            let num_restored += 1
         endif
      endif
   endfor
endfunction


if v:vim_did_enter
   call s:init()
else
   au VimEnter * call s:init()
endif

let &cpo = s:cpo_save
unlet s:cpo_save
