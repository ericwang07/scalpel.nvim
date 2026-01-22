-- Full LSP setup test with buffer
vim.opt.runtimepath:prepend("/Users/ericwang/.config/nvim")
vim.opt.runtimepath:prepend("/Users/ericwang/.local/share/nvim/lazy/nvim-lspconfig")
vim.opt.runtimepath:prepend("/Users/ericwang/.local/share/nvim/lazy/mason.nvim")
vim.opt.runtimepath:prepend("/Users/ericwang/.local/share/nvim/lazy/mason-lspconfig.nvim")
vim.opt.runtimepath:prepend("/Users/ericwang/.local/share/nvim/lazy/cmp-nvim-lsp")
vim.opt.runtimepath:prepend("/Users/ericwang/.local/share/nvim/lazy/nvim-cmp")
vim.opt.runtimepath:prepend("/Users/ericwang/.local/share/nvim/lazy/plenary.nvim")

print("=== Full LSP Setup Test ===")

-- Setup mason first
local mason_ok, mason = pcall(require, "mason")
if mason_ok then
  mason.setup()
end

-- Setup mason-lspconfig
local mslsp_ok, mslsp = pcall(require, "mason-lspconfig")
if mslsp_ok then
  mslsp.setup()
end

-- Setup cmp-nvim-lsp for capabilities
local cmp_nvim_lsp_ok, cmp_nvim_lsp = pcall(require, "cmp_nvim_lsp")
if cmp_nvim_lsp_ok then
  cmp_nvim_lsp.setup()
end

-- Setup lspconfig servers as in kickstart
local lspconfig_ok, lspconfig = pcall(require, "lspconfig")

-- Get capabilities
local capabilities = vim.lsp.protocol.make_client_capabilities()
capabilities = vim.tbl_deep_extend('force', capabilities, cmp_nvim_lsp.default_capabilities())

-- Servers configuration
local servers = {
  pyright = {
    settings = {
      python = {
        analysis = {
          exclude = { '**/node_modules', '**/venv', '**/.venv' },
        },
      },
    },
  },
  rust_analyzer = {},
  lua_ls = {
    settings = {
      Lua = {
        runtime = { version = 'LuaJIT' },
        workspace = {
          checkThirdParty = false,
          library = {
            '${3rd}/luv/library',
            unpack(vim.api.nvim_get_runtime_file('', true)),
          },
        },
        completion = {
          callSnippet = 'Replace',
        },
      },
    },
  },
}

-- Configure each server
for server_name, server_config in pairs(servers) do
  print("\nConfiguring " .. server_name .. "...")
  local config = vim.tbl_deep_extend('force', {}, server_config)
  config.capabilities = capabilities
  lspconfig[server_name].setup(config)
end

-- Enable the servers
print("\nEnabling servers...")
vim.lsp.enable({ 'pyright', 'lua_ls', 'rust_analyzer' })

-- Create a test buffer with Lua content
print("\nCreating test buffer...")
vim.api.nvim_command("enew")
vim.api.nvim_buf_set_lines(0, 0, -1, false, {
  "function hello()",
  "  print('world')",
  "end",
})

-- Set filetype
vim.bo.filetype = "lua"

-- Trigger LspAttach manually
print("\nTriggering LspAttach...")
vim.api.nvim_exec_autocmds('BufEnter', { pattern = '*' })

-- Check results
print("\n=== Results ===")

-- List active clients
print("\nActive LSP clients:")
local clients = vim.lsp.get_clients()
print("Count:", #clients)
for i, client in ipairs(clients) do
  print(string.format("  %d. %s (id=%d)", i, client.name, client.id))
end

print("\nClients for current buffer (bufnr=" .. vim.api.nvim_get_current_buf() .. "):")
local buf_clients = vim.lsp.get_active_clients({ bufnr = vim.api.nvim_get_current_buf() })
print("Count:", #buf_clients)
for i, client in ipairs(buf_clients) do
  print(string.format("  %d. %s (id=%d)", i, client.name, client.id))
end

print("\n=== Test Complete ===")
