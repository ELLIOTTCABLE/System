" Disable the terrible delete-whitespace-after-indenting functionality.
set cpoptions+=I

iunmap <CR>
inoremap <special> <CR> x<BS><CR>
inoremap <special> <C-[> x<BS><C-[>
