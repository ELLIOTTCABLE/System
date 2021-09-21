-- vim:foldmethod=marker:foldlevel=0:

-- treesitter {{{1
require'nvim-treesitter.configs'.setup {
   ensure_installed = "maintained",
   highlight = {
      enable = true,              -- false will disable the whole extension
      disable = { "typescript" },  -- list of language that will be disabled

      -- Setting this to true will run `:h syntax` and tree-sitter at the same time.
      -- Set this to `true` if you depend on 'syntax' being enabled (like for indentation).
      -- Using this option may slow down your editor, and you may see some duplicate highlights.
      -- Instead of true it can also be a list of languages
      additional_vim_regex_highlighting = false,
   },

   incremental_selection = {
      enable = true,
      keymaps = {
         init_selection = "gnn",
         node_incremental = "grn",
         scope_incremental = "grc",
         node_decremental = "grm",
      },
   },
}

vim.g.goto_key_map['nn'] = 'incrsec-init'
vim.g.goto_key_map['rn'] = 'incrsec-node'
vim.g.goto_key_map['rc'] = 'incrsec-scope'
vim.g.goto_key_map['rm'] = 'incrsec-decr'



-- nvim-lightbulb {{{1
function _G.update_lightbulb()
   require"nvim-lightbulb".update_lightbulb {
      sign = { enabled = false },
      float = { enabled = false },
      virtual_text = { enabled = true },
   }
end

vim.cmd [[autocmd CursorHold,CursorHoldI * lua update_lightbulb()]]


-- nvim-web-devicons {{{1
require'nvim-web-devicons'.setup {
   -- globally enable default icons (default to false)
   -- will get overriden by `get_icons` option
   default = true;
}


-- trouble {{{1
require("trouble").setup {
   position = "top", -- position of the list can be: bottom, top, left, right
   height = 15, -- height of the trouble list when position is top or bottom
   mode = "lsp_workspace_diagnostics", -- "lsp_workspace_diagnostics", "lsp_document_diagnostics", "quickfix", "lsp_references", "loclist"

   action_keys = { -- key mappings for actions in the trouble list
      -- map to {} to remove a mapping, for example:
      -- close = {},
      close = "q", -- close the list
      cancel = "<esc>", -- cancel the preview and get back to your last window / buffer / cursor
      refresh = "r", -- manually refresh
      jump = {"<cr>", "<tab>"}, -- jump to the diagnostic or open / close folds
      open_split = { "<c-x>" }, -- open buffer in new split
      open_vsplit = { "<c-v>" }, -- open buffer in new vsplit
      open_tab = { "<c-t>" }, -- open buffer in new tab
      jump_close = {"o"}, -- jump to the diagnostic and close the list
      toggle_mode = "m", -- toggle between "workspace" and "document" diagnostics mode
      toggle_preview = "P", -- toggle auto_preview
      hover = "K", -- opens a small popup with the full multiline message
      preview = "p", -- preview the diagnostic location
      close_folds = {"zM", "zm"}, -- close all folds
      open_folds = {"zR", "zr"}, -- open all folds
      toggle_fold = {"zA", "za"}, -- toggle fold of current file
      previous = "k", -- preview item
      next = "j" -- next item
   },

   auto_open = true, -- automatically open the list when you have diagnostics
   auto_close = true, -- automatically close the list when you have no diagnostics
   auto_preview = false, -- automatically preview the location of the diagnostic. <esc> to close preview and go back to last window
   auto_fold = false, -- automatically fold a file trouble list at creation
}


-- indent_blankline.nvim {{{1
require("indent_blankline").setup {
   char_list = { "│", "" },
   buftype_exclude = {"terminal"},
   filetype_exclude = {"help", "startify"},
   use_treesitter = true,
   show_current_context = true,
   viewport_buffer = 100,
   show_first_indent_level = false,
}


-- todo-comments.nvim {{{1
require("todo-comments").setup {
   -- keywords recognized as todo comments
   keywords = {
      DOC = {
         icon = " ", -- icon used for the sign, and in search results
         color = "info", -- can be a hex color, or a named color (see below)
         alt = { "DOCME" }, -- a set of other keywords that all map to this FIX keywords
      },
   },
   merge_keywords = true, -- when true, custom keywords will be merged with the defaults
   highlight = {
      before = "", -- "fg" or "bg" or empty
      keyword = "wide", -- "fg", "bg", "wide" or empty. (wide is the same as bg, but will also highlight surrounding characters)
      after = "", -- "fg" or "bg" or empty
      exclude = {}, -- list of file types to exclude highlighting
   },
   -- list of named colors where we try to extract the guifg from the
   -- list of hilight groups or use the hex color if hl not found as a fallback
   colors = {
      error = { "LspDiagnosticsDefaultError", "ErrorMsg", "#DC2626" },
      warning = { "LspDiagnosticsDefaultWarning", "WarningMsg", "#FBBF24" },
      info = { "LspDiagnosticsDefaultInformation", "#2563EB" },
      hint = { "LspDiagnosticsDefaultHint", "#10B981" },
      default = { "Identifier", "#7C3AED" },
   },
}


-- close-buffers.nvim {{{1
require('close_buffers').setup({
   preserve_window_layout = { 'this', 'nameless' },  -- Types of deletion that should preserve the window layout
})


-- lightspeed.nvim {{{1
require'lightspeed'.setup({
})
