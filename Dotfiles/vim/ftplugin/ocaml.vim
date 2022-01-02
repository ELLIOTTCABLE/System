runtime! ftplugin/ocaml_or_reason.vim

" Need to override `ocp-indent.vim`'s built-in indentexpr with `let-def/ocp-indent-vim`'s.
"setlocal indentexpr=ocpindent#OcpIndentLine()
let &l:formatprg = 'refmt --parse ml --print ml' .
 \ ' --print-width ' . &l:textwidth .
 \ ' --interface ' . (match(expand('%'), '\\.mli$') == -1 ? 'false' : 'true')
