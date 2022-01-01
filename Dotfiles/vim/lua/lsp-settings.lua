-- Mostly shamelessly stolen from Karim:
--    <https://github.com/kabouzeid/nvim-lspinstall/wiki>

-- Uncomment to enable debugging:
-- vim.lsp.set_log_level("debug")

vim.cmd("command! LspEditLog lua vim.cmd('e'..vim.lsp.get_log_path())")

-- keymaps
local common_on_attach = function(client, bufnr)
   local function buf_map(...) vim.api.nvim_buf_set_keymap(bufnr, ...) end
   local function buf_set_option(...) vim.api.nvim_buf_set_option(bufnr, ...) end

   local function buf_map_goto(mode, mapping, desc, ...)
      vim.g.goto_key_map[mapping] = desc
      print(desc)
      buf_map(mode, "g" .. mapping, ...)
   end

   local function buf_map_ll(mode, mapping, desc, ...)
      vim.g.localleader_key_map[mapping] = desc
      buf_map(mode, "<LocalLeader>" .. mapping, ...)
   end

   buf_set_option('omnifunc', 'v:lua.vim.lsp.omnifunc')

   -- Mappings for LSP-enabled buffers.
   local opts = { noremap = true, silent = true }
   buf_map("n", "<C-k>", "<cmd>lua vim.lsp.buf.signature_help()<CR>", opts)
   buf_map("n", "[d", "<cmd>lua vim.lsp.diagnostic.goto_prev()<CR>", opts)
   buf_map("n", "]d", "<cmd>lua vim.lsp.diagnostic.goto_next()<CR>", opts)

   buf_map_goto("n", "D", "goto-decl", "<Cmd>lua vim.lsp.buf.declaration()<CR>", opts)
   buf_map_goto("n", "d", "goto-def", "<Cmd>lua vim.lsp.buf.definition()<CR>", opts)
   buf_map_goto("n", "i", "goto-impl", "<cmd>lua vim.lsp.buf.implementation()<CR>", opts)
   buf_map_goto("n", "r", "goto-refs", "<cmd>lua vim.lsp.buf.references()<CR>", opts)
   buf_map_goto("n", "R", "list-refs", "<cmd>Trouble lsp_references<cr>", opts)

   buf_map_ll("n", "a", "code-action", "<cmd>lua vim.lsp.buf.code_action()<CR>", opts)
   buf_map_ll("n", "wa", "add-wfolder", "<cmd>lua vim.lsp.buf.add_workspace_folder()<CR>", opts)
   buf_map_ll("n", "wr", "remove-wfolder", "<cmd>lua vim.lsp.buf.remove_workspace_folder()<CR>", opts)
   buf_map_ll("n", "wl", "list-wfolder",
      "<cmd>lua print(vim.inspect(vim.lsp.buf.list_workspace_folders()))<CR>", opts)
   buf_map_ll("n", "D", "goto-typedef", "<cmd>lua vim.lsp.buf.type_definition()<CR>", opts)
   buf_map_ll("n", "rn", "rename", "<cmd>lua vim.lsp.buf.rename()<CR>", opts)
   buf_map_ll("n", "e", "show-diags", "<cmd>lua vim.lsp.diagnostic.show_line_diagnostics()<CR>", opts)
   buf_map_ll("n", "q", "set-loclist", "<cmd>lua vim.lsp.diagnostic.set_loclist()<CR>", opts)
   buf_map_ll("n", "f", "format", "<cmd>lua vim.lsp.buf.formatting()<CR>", opts)
   buf_map_ll("v", "f", "range-format", "<cmd>lua vim.lsp.buf.range_formatting()<CR>", opts)
   buf_map_ll("n", "l", "codelens", "<cmd>lua vim.lsp.codelens.run()<CR>", opts)

   buf_map_ll("n", "xx", "list-open", "<cmd>Trouble<cr>", opts)
   buf_map_ll("n", "xw", "list-wspace-diag", "<cmd>Trouble lsp_workspace_diagnostics<cr>", opts)
   buf_map_ll("n", "xd", "list-doc-diag", "<cmd>Trouble lsp_document_diagnostics<cr>", opts)
   buf_map_ll("n", "xl", "list-loclist", "<cmd>Trouble loclist<cr>", opts)
   buf_map_ll("n", "xq", "list-quickfix", "<cmd>Trouble quickfix<cr>", opts)
   buf_map_ll("n", "xq", "list-quickfix", "<cmd>Trouble quickfix<cr>", opts)

   -- vim already has builtin docs
   if vim.bo.ft ~= "vim" then buf_map("n", "K", "<Cmd>lua vim.lsp.buf.hover()<CR>", opts) end

   -- Set some keybinds conditional on server capabilities
   if client.resolved_capabilities.document_formatting then
      buf_map("n", "<space>rf", "<cmd>lua vim.lsp.buf.formatting()<CR>", opts)
   elseif client.resolved_capabilities.document_range_formatting then
      buf_map("n", "<space>rf", "<cmd>lua vim.lsp.buf.range_formatting()<CR>", opts)
   end

   -- Set autocommands conditional on server_capabilities
   if client.resolved_capabilities.document_highlight then
      vim.api.nvim_exec([[
         augroup lsp_document_highlight
            autocmd! * <buffer>
            autocmd CursorHold <buffer> lua vim.lsp.buf.document_highlight()
            autocmd CursorMoved <buffer> lua vim.lsp.buf.clear_references()
         augroup END
      ]], false)
   end

   -- TODO: Make this configurable via a buffer-local variable, and add a bind to toggle it
   if client.resolved_capabilities.document_formatting then
      vim.api.nvim_exec([[
         augroup lsp_format_on_save
            autocmd! * <buffer>
            autocmd BufWritePre <buffer> lua vim.lsp.buf.formatting_sync()
         augroup END
      ]], false)
   end

   if client.resolved_capabilities.code_lens then
      vim.api.nvim_exec([[
         augroup lsp_codelens
            autocmd! * <buffer>
            autocmd BufEnter,CursorHold,InsertLeave <buffer> lua vim.lsp.codelens.refresh()
         augroup END
      ]], false)
   end
end

-- Configure lua language server for neovim development
local lua_settings = {
   Lua = {
      runtime = {
         -- LuaJIT in the case of Neovim
         version = 'LuaJIT',
         path = vim.split(package.path, ';'),
      },
      diagnostics = {
         -- Get the language server to recognize the `vim` global
         -- FIXME: Why doesn't this seem to work? o_O  ~elliottcable
         globals = {'vim'},
      },
      workspace = {
         -- Make the server aware of Neovim runtime files
         library = {
            [vim.fn.expand('$VIMRUNTIME/lua')] = true,
            [vim.fn.expand('$VIMRUNTIME/lua/vim/lsp')] = true,
         },
      },
   }
}

-- {{{ omnisharp
local pid = vim.fn.getpid()
local omnisharp_bin = '/usr/local/bin/omnisharp'

local omnisharp_cmd = { omnisharp_bin, "--languageserver" , "--hostPID", tostring(pid) }
-- }}}

-- config that activates keymaps and enables snippet support
local function make_config()
   local capabilities = vim.lsp.protocol.make_client_capabilities()
   capabilities.textDocument.completion.completionItem.snippetSupport = true
   return {
      -- enable snippet support
      capabilities = capabilities,
      -- map buffer local keybindings when the language server attaches
      on_attach = common_on_attach,
   }
end


local lsp_installer = require("nvim-lsp-installer")

-- Register a handler that will be called for all installed servers.
-- Alternatively, you may also register handlers on specific server instances instead (see example below).
lsp_installer.on_server_ready(function(server)
   local config = make_config()

   -- language specific config
   if server.name == "sumneko_lua" then
      config.settings = lua_settings
   end

   if server.name == "jsonls" then
      local filetypes = require('lspconfig.server_configurations.' .. server.name)
         .default_config.filetypes

      -- Add jsonc
      vim.list_extend(filetypes, { "jsonc" })
   end

   -- This setup() function is exactly the same as lspconfig's setup function.
   -- Refer to https://github.com/neovim/nvim-lspconfig/blob/master/doc/server_configurations.md
   server:setup(config)
end)
