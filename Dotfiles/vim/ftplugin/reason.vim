runtime! ftplugin/ocaml_or_reason.vim

let &l:formatprg = 'refmt --parse re --print re --print-width ' . &l:textwidth .
 \ ' --interface ' . (match(expand('%'), '\\.rei$') == -1 ? 'false' : 'true')
