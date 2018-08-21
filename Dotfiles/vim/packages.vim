function! PlugIf(cond, ...)
   let opts = get(a:000, 0, {})
   return a:cond ? opts : extend(opts, { 'on': [], 'for': [] })
endfunction

" Specify a directory for plugins
" - For Neovim: ~/.local/share/nvim/plugged
" - Avoid using standard Vim directory names like 'plugin'
call plug#begin('~/.local/share/nvim/plugged')

Plug 'mhinz/vim-startify'

Plug 'itchyny/lightline.vim'
Plug 'taohexxx/lightline-buffer'

Plug 'airblade/vim-gitgutter'
Plug 'jacquesbh/vim-showmarks'
Plug 'junegunn/goyo.vim'                     " “Focused” mode

Plug 'vim-syntastic/syntastic'

"Plug 'amerlyq/vim-focus-autocmd'

Plug 'editorconfig/editorconfig-vim'

" ### Navigation
Plug 'cskeeters/vim-smooth-scroll'

Plug 'easymotion/vim-easymotion'
Plug 'haya14busa/incsearch.vim'
Plug 'haya14busa/incsearch-easymotion.vim'

" Pending:
"    <https://github.com/ocaml/merlin/issues/729>
"Plug 'ctrlpvim/ctrlp.vim', { 'for': ['ocaml'] }

Plug 'mileszs/ack.vim'

Plug 'Shougo/denite.nvim'
Plug 'chemzqm/unite-location'


" #### Completion
Plug 'Shougo/deoplete.nvim', { 'do': ':UpdateRemotePlugins' }
"Plug 'ervandew/supertab' " FIXME: HOW DO COMPLETUN WERK

Plug 'SirVer/ultisnips'
Plug 'honza/vim-snippets'

Plug 'carlitux/deoplete-ternjs', {
 \ 'for': ['javascript', 'javascript.jsx'],
 \ 'do': 'NODENV_VERSION=system nodenv exec npm install -g tern'
 \ }

Plug 'copy/deoplete-ocaml', { 'for': ['ocaml'] }

" #### Languages
Plug 'autozimu/LanguageClient-neovim', {
 \ 'for': ['ocaml', 'reason'],
 \ 'branch': 'next',
 \ 'do': 'bash install.sh',
 \ }

Plug 'reasonml-editor/vim-reason-plus', {
 \ 'for': ['ocaml', 'reason'],
 \ }

Plug 'sheerun/vim-polyglot'
Plug 'HerringtonDarkholme/yats.vim'

" Pending sheerun/vim-polyglot#320.
if !exists('g:polyglot_disabled') | let g:polyglot_disabled = [] | endif
let g:polyglot_disabled += ['ocaml']

Plug 'rgrinberg/vim-ocaml'

Plug 'tpope/vim-scriptease'

" #### Colourschemes & appearance
" I'm using different colourschemes in GUI and TUI vims.
" First, the backup, Terminal theme:
Plug 'lifepillar/vim-solarized8'
Plug 'miyakogi/seiya.vim', PlugIf(!has('gui_vimr'))

" Second, my actual, VimR/gui setup:
Plug 'chriskempson/base16-vim'   " light theme (base16-atelier-lakeside-light)
Plug 'arcticicestudio/nord-vim'  " dark theme

" Finally, the "manpage" theme
Plug 'logico-dev/typewriter'


" #### Small utilities
Plug 'tpope/vim-fugitive'
Plug 'tpope/vim-eunuch' " Necessary for :Move, :Rename, :Delete, etc
Plug 'tpope/vim-abolish' " Life is unlivable without :Subvert. Let's be real.
Plug 'tpope/vim-surround'
Plug 'tpope/vim-unimpaired'
Plug 'tpope/vim-repeat'
Plug 'matze/vim-move'
Plug 'takac/vim-hardtime'
Plug 'AndrewRadev/bufferize.vim'
Plug 'tomtom/tcomment_vim'

" I don't *love* including these from the dead, unmaintained gh/vim-scripts, but ...
Plug 'vim-scripts/ShowTrailingWhitespace'
Plug 'vim-scripts/DeleteTrailingWhitespace'

Plug 'Shougo/echodoc.vim'

" #### Late-loaders (come on, vim-plug, support `defer:`!)
Plug 'ryanoasis/vim-devicons'


" ## added by OPAM user-setup for vim / base ## 93ee63e278bdfc07d1139a748ed3fff2 ## you can edit, but keep this line
" NOTE: Modified to use vim-plug, instead of directly modifying `rtp`. ~ELLIOTTCABLE
let s:opam_share_dir = system('opam config var share')
let s:opam_share_dir = substitute(s:opam_share_dir, '[\r\n]*$', '', '')

let s:opam_configuration = {}

function! OpamConfOcpIndent()
   call plug#(fnameescape(s:opam_share_dir . '/ocp-indent/vim'))
endfunction
let s:opam_configuration['ocp-indent'] = function('OpamConfOcpIndent')

function! OpamConfOcpIndex()
   call plug#(fnameescape(s:opam_share_dir . '/ocp-index/vim'))
endfunction
let s:opam_configuration['ocp-index'] = function('OpamConfOcpIndex')

function! OpamConfMerlin()
  call plug#(fnameescape(s:opam_share_dir . '/merlin/vim'))
endfunction
let s:opam_configuration['merlin'] = function('OpamConfMerlin')


if g:use_own_merlin
   let s:opam_packages = ["ocp-indent", "ocp-index"]
   Plug '~/Documents/Code/Source/merlin/vim/merlin/'
else
   let s:opam_packages = ["ocp-indent", "ocp-index", "merlin"]
endif

let s:opam_check_cmdline = ["opam list --installed --short --safe --color=never"] + s:opam_packages
let s:opam_available_tools = split(system(join(s:opam_check_cmdline)))
for tool in s:opam_packages
   " Respect package order (merlin should be after ocp-index)
   if count(s:opam_available_tools, tool) > 0
      call s:opam_configuration[tool]()
   endif
endfor
" ## end of OPAM user-setup addition for vim / base ## keep this line

" Has to come last, to override `ocp-indent.vim`'s `indentexpr` setting.
Plug 'let-def/ocp-indent-vim'


" Initialize plugin system
call plug#end()
