syn clear   gitcommitSummary
syn match   gitcommitSummary    "^.\{0,76\}" contained containedin=gitcommitFirstLine nextgroup=gitcommitOverflow contains=@Spell
