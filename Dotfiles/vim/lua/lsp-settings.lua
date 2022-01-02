-- Much of this was shamelessly stolen from Karim:
--    <https://github.com/kabouzeid/nvim-lspinstall/wiki>

-- To enable debugging:
-- 1. Uncomment this,
-- vim.lsp.set_log_level("debug")
-- 2. ... uncomment the `debug = true` argument to `null-ls` below

vim.cmd "command! LspEditLog lua vim.cmd('e'..vim.lsp.get_log_path())"

-- keymaps
local common_on_attach = function(client, bufnr)
   local function buf_map(...)
      vim.api.nvim_buf_set_keymap(bufnr, ...)
   end
   local function buf_set_option(...)
      vim.api.nvim_buf_set_option(bufnr, ...)
   end

   local function buf_map_goto(mode, mapping, desc, ...)
      vim.g.goto_key_map[mapping] = desc
      buf_map(mode, 'g' .. mapping, ...)
   end

   local function buf_map_ll(mode, mapping, desc, ...)
      vim.g.localleader_key_map[mapping] = desc
      buf_map(mode, '<LocalLeader>' .. mapping, ...)
   end

   buf_set_option('omnifunc', 'v:lua.vim.lsp.omnifunc')

   -- Mappings for LSP-enabled buffers.
   local opts = { noremap = true, silent = true }
   buf_map('n', '<C-k>', '<cmd>lua vim.lsp.buf.signature_help()<CR>', opts)
   buf_map('n', '[d', '<cmd>lua vim.lsp.diagnostic.goto_prev()<CR>', opts)
   buf_map('n', ']d', '<cmd>lua vim.lsp.diagnostic.goto_next()<CR>', opts)

   buf_map_goto('n', 'D', 'goto-decl', '<Cmd>lua vim.lsp.buf.declaration()<CR>', opts)
   buf_map_goto('n', 'd', 'goto-def', '<Cmd>lua vim.lsp.buf.definition()<CR>', opts)
   buf_map_goto('n', 'i', 'goto-impl', '<cmd>lua vim.lsp.buf.implementation()<CR>', opts)
   buf_map_goto('n', 'r', 'goto-refs', '<cmd>lua vim.lsp.buf.references()<CR>', opts)
   buf_map_goto('n', 'R', 'list-refs', '<cmd>Trouble lsp_references<cr>', opts)

   buf_map_ll('n', 'a', 'code-action', '<cmd>lua vim.lsp.buf.code_action()<CR>', opts)
   buf_map_ll('n', 'wa', 'add-wfolder', '<cmd>lua vim.lsp.buf.add_workspace_folder()<CR>', opts)
   buf_map_ll('n', 'wr', 'remove-wfolder', '<cmd>lua vim.lsp.buf.remove_workspace_folder()<CR>', opts)
   buf_map_ll('n', 'wl', 'list-wfolder', '<cmd>lua print(vim.inspect(vim.lsp.buf.list_workspace_folders()))<CR>', opts)
   buf_map_ll('n', 'D', 'goto-typedef', '<cmd>lua vim.lsp.buf.type_definition()<CR>', opts)
   buf_map_ll('n', 'rn', 'rename', '<cmd>lua vim.lsp.buf.rename()<CR>', opts)
   buf_map_ll('n', 'e', 'show-diags', '<cmd>lua vim.lsp.diagnostic.show_line_diagnostics()<CR>', opts)
   buf_map_ll('n', 'q', 'set-loclist', '<cmd>lua vim.lsp.diagnostic.set_loclist()<CR>', opts)
   buf_map_ll('n', 'f', 'format', '<cmd>lua vim.lsp.buf.formatting()<CR>', opts)
   buf_map_ll('v', 'f', 'range-format', '<cmd>lua vim.lsp.buf.range_formatting()<CR>', opts)
   buf_map_ll('n', 'l', 'codelens', '<cmd>lua vim.lsp.codelens.run()<CR>', opts)

   buf_map_ll('n', 'xx', 'list-open', '<cmd>Trouble<cr>', opts)
   buf_map_ll('n', 'xw', 'list-wspace-diag', '<cmd>Trouble lsp_workspace_diagnostics<cr>', opts)
   buf_map_ll('n', 'xd', 'list-doc-diag', '<cmd>Trouble lsp_document_diagnostics<cr>', opts)
   buf_map_ll('n', 'xl', 'list-loclist', '<cmd>Trouble loclist<cr>', opts)
   buf_map_ll('n', 'xq', 'list-quickfix', '<cmd>Trouble quickfix<cr>', opts)
   buf_map_ll('n', 'xq', 'list-quickfix', '<cmd>Trouble quickfix<cr>', opts)

   -- vim already has builtin docs
   if vim.bo.ft ~= 'vim' then
      buf_map('n', 'K', '<Cmd>lua vim.lsp.buf.hover()<CR>', opts)
   end

   -- Set some keybinds conditional on server capabilities
   if client.resolved_capabilities.document_formatting then
      buf_map('n', '<space>rf', '<cmd>lua vim.lsp.buf.formatting()<CR>', opts)
   elseif client.resolved_capabilities.document_range_formatting then
      buf_map('n', '<space>rf', '<cmd>lua vim.lsp.buf.range_formatting()<CR>', opts)
   end

   -- Set autocommands conditional on server_capabilities
   if client.resolved_capabilities.document_highlight then
      vim.cmd [[
         augroup lsp_document_highlight
            autocmd! * <buffer>
            autocmd CursorHold <buffer> lua vim.lsp.buf.document_highlight()
            autocmd CursorMoved <buffer> lua vim.lsp.buf.clear_references()
         augroup END
      ]]
   end

   -- TODO: Make this configurable via a buffer-local variable, and add a bind to toggle it
   if client.resolved_capabilities.document_formatting then
      vim.cmd [[
         augroup lsp_format_on_save
            autocmd! * <buffer>
            autocmd BufWritePre <buffer> lua vim.lsp.buf.formatting_sync()
         augroup END
      ]]
   end

   if client.resolved_capabilities.code_lens then
      vim.cmd [[
         augroup lsp_codelens
            autocmd! * <buffer>
            autocmd BufEnter,CursorHold,InsertLeave <buffer> lua vim.lsp.codelens.refresh()
         augroup END
      ]]
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
         globals = { 'vim' },
      },
      workspace = {
         -- Make the server aware of Neovim runtime files
         library = {
            [vim.fn.expand '$VIMRUNTIME/lua'] = true,
            [vim.fn.expand '$VIMRUNTIME/lua/vim/lsp'] = true,
         },
      },
   },
}

-- {{{ omnisharp
local pid = vim.fn.getpid()
local omnisharp_bin = '/usr/local/bin/omnisharp'

local omnisharp_cmd = { omnisharp_bin, '--languageserver', '--hostPID', tostring(pid) }
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

local null_ls = require 'null-ls'
local methods = require 'null-ls.methods'

null_ls.setup {
   -- debug = true,
   on_attach = common_on_attach,
   sources = {
      -- JavaScript / TypeScript
      -- (Use `prettier` only for range-formatting; fall back to `prettierd` for normal usage.)
      null_ls.builtins.formatting.prettier.with {
         method = { methods.internal.RANGE_FORMATTING },
         prefer_local = 'node_modules/.bin',
      },
      null_ls.builtins.formatting.prettierd,
      null_ls.builtins.diagnostics.eslint_d,
      null_ls.builtins.code_actions.eslint_d,

      -- lua
      null_ls.builtins.formatting.stylua,
      null_ls.builtins.diagnostics.selene,

      -- misc
      null_ls.builtins.diagnostics.vint,
      null_ls.builtins.diagnostics.yamllint,
   },
}

local lsp_installer = require 'nvim-lsp-installer'

-- Register a handler that will be called for all installed servers.
-- Alternatively, you may also register handlers on specific server instances instead (see example below).
lsp_installer.on_server_ready(function(server)
   local config = make_config()
   local filetypes = require('lspconfig.server_configurations.' .. server.name).default_config.filetypes

   -- language specific config

   if server.name == 'sumneko_lua' then
      config.settings = lua_settings
   end

   if server.name == 'jsonls' then
      -- Add jsonc
      vim.list_extend(filetypes, { 'jsonc' })
   end

   -- Disable JavaScript formatters, so they don't conflict with null-ls / Prettier:
   --    <https://github.com/jose-elias-alvarez/null-ls.nvim/wiki/Avoiding-LSP-formatting-conflicts>
   if vim.tbl_contains({ 'jsonls', 'stylelint_lsp', 'tsserver' }, server.name) then
      local orig_on_attach = config.on_attach

      config.on_attach = function(client, bufnr)
         client.resolved_capabilities.document_formatting = false
         client.resolved_capabilities.document_range_formatting = false

         orig_on_attach(client, bufnr)
      end
   end

   -- This setup() function is exactly the same as lspconfig's setup function.
   -- Refer to https://github.com/neovim/nvim-lspconfig/blob/master/doc/server_configurations.md
   server:setup(config)
end)
