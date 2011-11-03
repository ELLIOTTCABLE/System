runtime bundle/vim-pathogen/autoload/pathogen.vim
call pathogen#infect()

set nomodeline
set nocompatible

colorscheme solarized

set textwidth=100
set number ruler nowrap
set shiftround expandtab tabstop=8 softtabstop=3 shiftwidth=3
set nosmarttab noautoindent
set smartcase ignorecase

set cursorline
set listchars+=tab:\ ·

set hlsearch incsearch ignorecase smartcase

set scrolloff=3
set history=1000
set title

" Line wrapping
set cpoptions+=n  " Uses line-numbering columns for line-wrapping indicator
let &showbreak = '  ➤ '  " FIXME: Currently not hilighted the same as line numbers

syntax on
filetype on
filetype plugin on
filetype indent off

set encoding=utf-8

" Tab completion
set wildmode=list:longest,list:full
set wildignore+=*.o,*.obj,.git,*.class,.svn

" These make movement commands “work” with `o`, such as `3o` to insert inject lines and switch to insert mode.
nnoremap o o<Esc>S
nnoremap O O<Esc>'[S

" Fuck '.
nnoremap ' `
nnoremap ` '

" See `:help Y`
map Y y$


autocmd BufLeave,FocusLost silent! wall

" gist-vim defaults
if has("mac")
  let g:gist_clip_command = 'pbcopy'
elseif has("unix")
  let g:gist_clip_command = 'xclip -selection clipboard'
endif
let g:gist_detect_filetype = 1
let g:gist_open_browser_after_post = 1

" Directories for swp files
set backupdir=~/.vim/backup
set directory=~/.vim/backup

set statusline=%<%f\ %h%m%r%{fugitive#statusline()}%=%-14.(%l,%c%V%)\ %P

" === Plugins ===
let g:solarized_termtrans = 1
if has('gui_running')
   set background=light
else
   set background=dark
endif


" filnxtToO → ilmxstToOI
" (Last `shm+=I` disables the :intro message.)
set shortmess-=f shm+=m shm-=n shm+=s shm+=I
set showcmd

set runtimepath+=~/.vim.local/after
