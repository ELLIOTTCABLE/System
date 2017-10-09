function! PlugIf(cond, ...)
   let opts = get(a:000, 0, {})
   return a:cond ? opts : extend(opts, { 'on': [], 'for': [] })
endfunction

" Specify a directory for plugins
" - For Neovim: ~/.local/share/nvim/plugged
" - Avoid using standard Vim directory names like 'plugin'
call plug#begin('~/.local/share/nvim/plugged')

Plug 'airblade/vim-gitgutter'
Plug 'jacquesbh/vim-showmarks'

Plug 'amerlyq/vim-focus-autocmd'

Plug 'sheerun/vim-polyglot'
Plug 'HerringtonDarkholme/yats.vim'

Plug 'mhartington/oceanic-next'

" VimR already has a GUI buffer-explorer built-in
Plug 'ap/vim-buftabline', PlugIf(!has('gui_running'))

" Initialize plugin system
call plug#end()
