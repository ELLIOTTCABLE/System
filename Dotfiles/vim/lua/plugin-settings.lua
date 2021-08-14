-- nvim-lightbulb {{{

function _G.update_lightbulb()
  require"nvim-lightbulb".update_lightbulb {
    sign = { enabled = false },
    float = { enabled = false },
    virtual_text = { enabled = true },
  }
end

vim.cmd [[autocmd CursorHold,CursorHoldI * lua update_lightbulb()]]

-- }}}
