function! PlugIf(cond, ...)
   let opts = get(a:000, 0, {})
   return a:cond ? opts : extend(opts, { 'on': [], 'for': [] })
endfunction

" Specify a directory for plugins
" - For Neovim: ~/.local/share/nvim/plugged
" - Avoid using standard Vim directory names like 'plugin'
call plug#begin('~/.local/share/nvim/plugged')

Plug 'itchyny/lightline.vim'

Plug 'airblade/vim-gitgutter'
Plug 'jacquesbh/vim-showmarks'
Plug 'junegunn/goyo.vim'                     " “Focused” mode

Plug 'vim-syntastic/syntastic'

"Plug 'amerlyq/vim-focus-autocmd'

" ### Navigation
Plug 'cskeeters/vim-smooth-scroll'

Plug 'easymotion/vim-easymotion'
Plug 'haya14busa/incsearch.vim'
Plug 'haya14busa/incsearch-easymotion.vim'

" Pending:
"    <https://github.com/ocaml/merlin/issues/729>
"Plug 'ctrlpvim/ctrlp.vim', { 'for': ['ocaml'] }

Plug 'Shougo/denite.nvim'


" #### Completion
Plug 'Shougo/deoplete.nvim', { 'do': ':UpdateRemotePlugins' }
Plug 'ervandew/supertab'

Plug 'SirVer/ultisnips'
Plug 'honza/vim-snippets'

Plug 'carlitux/deoplete-ternjs', { 'for': ['javascript', 'javascript.jsx'], 'do': 'NODENV_VERSION=system nodenv exec npm install -g tern' }

" #### Languages
Plug 'sheerun/vim-polyglot'
Plug 'HerringtonDarkholme/yats.vim'

" #### Colourschemes & appearance
" I'm using different colourschemes in GUI and TUI vims.
Plug 'arcticicestudio/nord-vim'
Plug 'lifepillar/vim-solarized8'
Plug 'miyakogi/seiya.vim', PlugIf(!has('gui_vimr'))

" #### Small utilities
Plug 'matze/vim-move'
Plug 'takac/vim-hardtime'

" I don't *love* including these from the dead, unmaintained gh/vim-scripts, but ...
Plug 'vim-scripts/ShowTrailingWhitespace'
Plug 'vim-scripts/DeleteTrailingWhitespace'

Plug 'Shougo/echodoc.vim'

" #### Late-loaders (come on, vim-plug, support `defer:`!)
Plug 'ryanoasis/vim-devicons'

" Initialize plugin system
call plug#end()
