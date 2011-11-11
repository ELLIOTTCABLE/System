set nomodeline nocompatible
runtime bundle/vim-pathogen/autoload/pathogen.vim
call pathogen#infect()

runtime solarized.vimrc

set textwidth=100
set number ruler nowrap
set shiftround expandtab tabstop=8 softtabstop=3 shiftwidth=3
set nosmarttab noautoindent
set smartcase ignorecase

set cursorline
set listchars+=tab:\ ·

set hlsearch incsearch ignorecase smartcase gdefault

set scrolloff=3
set history=1000
set title

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


autocmd BufLeave,FocusLost * silent! wall

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
let NERDChristmasTree = 1
let NERDTreeBookmarksFile = '~/.vim/.NERDTreeBookmarks'
let NERDTreeMouseMode = 2
let NERDTreeSortOrder = ['\/$', '\.h$', '*']
let NERDTreeWinPos = 'right'
let NERDTreeMinimalUI = 1
let NERDTreeDirArrows = 1

let NERDBlockComIgnoreEmpty = 0
let NERDSpaceDelims = 1
let NERDCompactSexyComs = 1
let NERDDefaultNesting = 0

let g:CommandTMaxCachedDirectories = 0
let g:CommandTMaxHeight = 10
let g:CommandTMatchWindowReverse = 1
let g:CommandTScanDotDirectories = 1  " `:set wildignore` handles this better.

" filnxtToO → ilmxstToOI
" (Last `shm+=I` disables the :intro message.)
set shortmess-=f shm+=m shm-=n shm+=s shm+=I
set showcmd
