" A vim-script to setup a manpage-view

function! vimman#(...)
   SafeColorscheme typewriter

   nnoremap q :<C-u>qa<CR>

   if a:0 >=# 1 && len(a:1) !=# 0
      execute "help " . a:1
   else
      help
   endif

   only
   Goyo 80x100%
   normal ze
endfunction
