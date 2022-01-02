" opam lockfile-configuration
augroup opam_detect | au!
   au BufRead,BufNewFile *.opam.locked set filetype=opam
augroup END
