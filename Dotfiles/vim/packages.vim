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
Plug 'junegunn/goyo.vim'                     " “Focused” mode
Plug 'vim-syntastic/syntastic'

Plug 'Shougo/denite.nvim'

" Pending:
"    <https://github.com/ocaml/merlin/issues/729>
"Plug 'ctrlpvim/ctrlp.vim', { 'for': ['ocaml'] }

Plug 'amerlyq/vim-focus-autocmd'
Plug 'cskeeters/vim-smooth-scroll'

Plug 'easymotion/vim-easymotion'

Plug 'Shougo/deoplete.nvim', { 'do': ':UpdateRemotePlugins' }
Plug 'ervandew/supertab'

Plug 'SirVer/ultisnips'
Plug 'honza/vim-snippets'

Plug 'carlitux/deoplete-ternjs', { 'for': ['javascript', 'javascript.jsx'], 'do': 'NODENV_VERSION=system nodenv exec npm install -g tern' }

Plug 'sheerun/vim-polyglot'
Plug 'HerringtonDarkholme/yats.vim'

" I'm using different colourschemes in GUI and TUI vims.
Plug 'arcticicestudio/nord-vim'
Plug 'lifepillar/vim-solarized8'
Plug 'miyakogi/seiya.vim', PlugIf(!has('gui_vimr'))

" VimR already has a GUI buffer-explorer built-in
Plug 'ap/vim-buftabline', PlugIf(!has('gui_vimr'))
Plug 'Shougo/echodoc.vim'

" Initialize plugin system
call plug#end()
