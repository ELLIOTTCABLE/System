" BuckleScript configuration
augroup bucklescript_detect | au!
   au BufRead,BufNewFile bsconfig.json set filetype=json5
augroup END
