" Specify a directory for plugins
" - For Neovim: ~/.local/share/nvim/plugged
" - Avoid using standard Vim directory names like 'plugin'
call plug#begin('~/.local/share/nvim/plugged')

Plug 'airblade/vim-gitgutter'
Plug 'jacquesbh/vim-showmarks'

Plug 'amerlyq/vim-focus-autocmd'

" Initialize plugin system
call plug#end()
