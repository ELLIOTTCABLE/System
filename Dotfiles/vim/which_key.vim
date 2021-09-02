if !exists('g:leader_key_map') | let g:leader_key_map = {} | endif
if !exists('g:localleader_key_map') | let g:localleader_key_map = {} | endif
if !exists('g:goto_key_map') | let g:goto_key_map = {} | endif
if !exists('g:fold_key_map') | let g:fold_key_map = {} | endif

" Need to duplicate built-in mappings so WhichKey can be aware of them
noremap <silent> g<C-G> g<C-G>
let g:goto_key_map['<C-G>'] = 'show-cursor-pos'

noremap <silent> gi gi
let g:goto_key_map.i = 'insert-at-last-insert-pos'
noremap <silent> gI gI
let g:goto_key_map.I = 'insert-at-col1'

noremap <silent> gq gq
let g:goto_key_map.q = 'format-motion'
noremap <silent> gw gw
let g:goto_key_map.w = 'format-motion-keep-cursor'

noremap <silent> ge ge
let g:goto_key_map.e = 'go-end-prev-word'
noremap <silent> gE gE
let g:goto_key_map.E = 'go-end-prev-WORD'
noremap <silent> gg gg
let g:goto_key_map.g = 'goto-top'
noremap <silent> gj gj
let g:goto_key_map.j = 'go-display-line-down'
noremap <silent> gk gk
let g:goto_key_map.k = 'go-display-line-up'
noremap <silent> g0 g0
let g:goto_key_map['0'] = 'go-display-column-0'
noremap <silent> g^ g^
let g:goto_key_map['^'] = 'go-display-start'
noremap <silent> g$ g$
let g:goto_key_map['$'] = 'go-display-end'
noremap <silent> gm gm
let g:goto_key_map.m = 'go-half-screenwidth-right'
noremap <silent> gM gM
let g:goto_key_map.m = 'go-percentage-of-line'
noremap <silent> g_ g_
let g:goto_key_map['_'] = 'go-under-last-char'
noremap <silent> g; g;
let g:goto_key_map[';'] = 'go-prev-change'
noremap <silent> g, g,
let g:goto_key_map[','] = 'go-next-change'
noremap <silent> go go
let g:goto_key_map.o = 'go-byte'

noremap <silent> gt gt
let g:goto_key_map.t = 'goto-next-tab'
noremap <silent> gT gT
let g:goto_key_map.T = 'goto-prev-tab'
noremap <silent> g<Tab> g<Tab>
let g:goto_key_map.T = 'goto-mru-tab'

noremap <silent> gf gf
let g:goto_key_map.f = 'goto-file'
noremap <silent> gF gF
let g:goto_key_map.F = 'goto-file-and-line'
noremap <silent> g8 g8
let g:goto_key_map['8'] = 'print-char-as-hex'
noremap <silent> g' g'
let g:goto_key_map["'"] = 'mark-without-jumplist'
noremap <silent> g` g`
let g:goto_key_map["`"] = 'mark-without-jumplist'
noremap <silent> g+ g+
let g:goto_key_map["+"] = 'undo-chrono-forward'
noremap <silent> g- g-
let g:goto_key_map["-"] = 'undo-chrono-backwards'

noremap <silent> g* g*
let g:goto_key_map["*"] = 'search-cword-forwards-in-word'
noremap <silent> g# g#
let g:goto_key_map["#"] = 'search-cword-backwards-in-word'

noremap <silent> gv gv
let g:goto_key_map.v = 'select-last-selection'
noremap <silent> gn gn
let g:goto_key_map.n = 'select-next-match'
noremap <silent> gN gN
let g:goto_key_map.N = 'select-prev-match'

noremap <silent> g~ g~
let g:goto_key_map["~"] = 'case-swap-motion'
noremap <silent> gu gu
let g:goto_key_map.u = 'case-lower-motion'
noremap <silent> gU gU
let g:goto_key_map.U = 'case-upper-motion'

noremap <silent> g] g]
let g:goto_key_map["]"] = 'select-from-matching-tags'

noremap <silent> g& g&
let g:goto_key_map["&"] = 'resub-with-last-search'
noremap <silent> gJ gJ
let g:goto_key_map.J = 'join-without-spaces'
noremap <silent> gr gr
let g:goto_key_map.r = 'virtual-replace-under-cursor'
noremap <silent> gR gR
let g:goto_key_map.R = 'virtual-replace-mode'
noremap <silent> gs gs
let g:goto_key_map.s = 'sleep'
noremap <silent> ga ga
let g:goto_key_map.a = 'print-ascii-value'


noremap <silent> z= z=
let g:fold_key_map['='] = 'spell-suggest'
noremap <silent> zg zg
let g:fold_key_map.g = 'spell-mark-good'
noremap <silent> zG zG
let g:fold_key_map.G = 'spell-mark-good-temp'
noremap <silent> zw zw
let g:fold_key_map.w = 'spell-mark-wrong'
noremap <silent> zW zW
let g:fold_key_map.W = 'spell-mark-wrong-temp'
noremap <silent> zug zug
let g:fold_key_map.ug = 'spell-undo-mark-good'
noremap <silent> zuG zuG
let g:fold_key_map.uG = 'spell-undo-mark-good-temp'
noremap <silent> zuw zuw
let g:fold_key_map.uw = 'spell-undo-mark-wrong'
noremap <silent> zuW zuW
let g:fold_key_map.uW = 'spell-undo-mark-wrong-temp'

noremap <silent> zf zf
let g:fold_key_map.f = 'fold-create-op'
noremap <silent> zF zF
let g:fold_key_map.F = 'fold-create-count'
noremap <silent> zd zd
let g:fold_key_map.d = 'fold-delete'
noremap <silent> zD zD
let g:fold_key_map.D = 'fold-delete-recur'
noremap <silent> zE zE
let g:fold_key_map.E = 'fold-eliminate-all'

noremap <silent> zo zo
let g:fold_key_map.o = 'fold-open-this'
noremap <silent> zO zO
let g:fold_key_map.O = 'fold-open-this-recur'
noremap <silent> zc zc
let g:fold_key_map.c = 'fold-close-this'
noremap <silent> zC zC
let g:fold_key_map.C = 'fold-close-this-recur'
noremap <silent> za za
let g:fold_key_map.a = 'fold-tAggle-this'
noremap <silent> zA zA
let g:fold_key_map.A = 'fold-tAggle-this-recur'
noremap <silent> zv zv
let g:fold_key_map.v = 'fold-view-cursor'
noremap <silent> zx zx
let g:fold_key_map.x = 'fold-reset'

noremap <silent> zm zm
let g:fold_key_map.m = 'fold-more'
noremap <silent> zM zM
let g:fold_key_map.M = 'fold-more-all'
noremap <silent> zr zr
let g:fold_key_map.r = 'fold-reduce'
noremap <silent> zR zR
let g:fold_key_map.R = 'fold-reduce-all'

noremap <silent> zn zn
let g:fold_key_map.n = 'folding-none'
noremap <silent> zN zN
let g:fold_key_map.N = 'folding-normal'
noremap <silent> zi zi
let g:fold_key_map.i = 'folding-toggle'

noremap <silent> zj zj
let g:fold_key_map.j = 'fold-jump-next'
noremap <silent> zk zk
let g:fold_key_map.f = 'fold-jump-prev'

noremap <silent> zl zl
let g:fold_key_map.l = 'scoll-horiz-right'
noremap <silent> zh zh
let g:fold_key_map.h = 'scoll-horiz-left'
noremap <silent> zL zL
let g:fold_key_map.L = 'scoll-horiz-right-halfscr'
noremap <silent> zH zH
let g:fold_key_map.H = 'scoll-horiz-left-halfscr'
noremap <silent> zs zs
let g:fold_key_map.s = 'scoll-horiz-start'
noremap <silent> ze ze
let g:fold_key_map.e = 'scoll-horiz-end'

noremap <silent> zt zt
let g:fold_key_map.t = 'scoll-cursor-to-top'
noremap <silent> zz zz
let g:fold_key_map.f = 'scroll-cursor-to-middle'
noremap <silent> zb zb
let g:fold_key_map.f = 'scroll-cursor-to-bottom'

noremap <silent> zp zp
let g:fold_key_map.p = 'paste-no-trailing'
noremap <silent> zP zP
let g:fold_key_map.P = 'paste-no-trailing-before'
noremap <silent> zy zy
let g:fold_key_map.y = 'yank-no-trailing'
