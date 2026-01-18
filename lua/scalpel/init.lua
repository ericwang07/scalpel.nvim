--[[
Scalpel - AI-Powered Code Completion for Neovim
===============================================

Main entry point for the Scalpel plugin. Handles setup, user commands,
keymaps, and exposes core functionality.

Architecture Overview:
  - server.lua: Server status checking (user-managed server)
  - client.lua: HTTP client for talking to the server
  - fetcher.lua: Background service that auto-fetches predictions
  - state.lua: Shared state (current prediction)
  - matcher.lua: Fuzzy matching logic
  - comparator.lua: nvim-cmp comparator (boosts matching items)
  - formatter.lua: nvim-cmp formatter (adds ⚡ indicator)
  - cmp.lua: nvim-cmp source (fallback suggestions)

Setup:
  require("scalpel").setup({
    port = 3000,  -- Server port
    keymaps = {
      complete = "<C-k>",  -- Manual completion trigger
    }
  })

User Commands:
  :ScalpelHealth   - Check if server is running
  :ScalpelComplete - Trigger manual completion

Server Management (User-Managed):
  The Scalpel server is managed by the user, not by the plugin.
  Start the server: $ scalpel start
  Stop the server:  $ scalpel stop

nvim-cmp Integration (Passive):
  Scalpel registers its components with nvim-cmp without overwriting your config.
  Your existing cmp.setup() continues to work as before.
--]]

local config = require("scalpel.config")
local server = require("scalpel.server")
local client = require("scalpel.client")
local fetcher = require("scalpel.fetcher")

local M = {}

--- Initializes the plugin
--- @param opts table|nil Configuration options
function M.setup(opts)
  config.setup(opts)

  fetcher.setup()

  if config.options.keymaps then
    if config.options.keymaps.complete then
      vim.keymap.set("n", config.options.keymaps.complete, function()
        M.trigger_completion()
      end, { desc = "Trigger Scalpel Completion" })
    end
  end

  vim.api.nvim_create_user_command("ScalpelHealth", function()
    server.health_check()
  end, {})

  vim.api.nvim_create_user_command("ScalpelComplete", function()
    M.trigger_completion()
  end, {})

  vim.fn.timer_start(500, function()
    local status = server.status()
    if status.running then
      vim.notify(
        string.format("Scalpel: Server is running on port %d", status.port),
        vim.log.levels.INFO
      )
    else
      vim.notify("Scalpel: Server is not running", vim.log.levels.WARN)
      vim.notify(
        "To start: run 'scalpel start' in your terminal, then :ScalpelHealth to verify",
        vim.log.levels.INFO
      )
    end
  end)
end

--- Manually triggers a completion request and displays the result
--- This is for debugging/testing - normal usage relies on the auto-fetcher
function M.trigger_completion()
  local buf = vim.api.nvim_get_current_buf()
  local win = vim.api.nvim_get_current_win()
  local cursor = vim.api.nvim_win_get_cursor(win)
  local row, col = cursor[1] - 1, cursor[2]

  local prefix_lines = vim.api.nvim_buf_get_text(buf, 0, 0, row, col + 1, {})
  local suffix_lines = vim.api.nvim_buf_get_text(buf, row, col + 1, -1, -1, {})

  local prefix = table.concat(prefix_lines, "\n")
  local suffix = table.concat(suffix_lines, "\n")
  local filetype = vim.bo[buf].filetype

  client.complete(prefix, suffix, filetype, function(res, err)
    if err then
      vim.schedule(function()
        vim.notify("Completion failed: " .. err, vim.log.levels.ERROR)
      end)
      return
    end

    if res and res.completion then
      vim.schedule(function()
        vim.notify("Scalpel Completion: " .. res.completion, vim.log.levels.INFO)
      end)
    end
  end)
end

--- Simplified nvim-cmp setup that handles all integration automatically
--- This is an alternative to calling setup() + manually configuring cmp
--- @param opts table|nil Configuration options (same as setup(), plus cmp_config)
---   opts.cmp_config: nvim-cmp config to merge with (sources, etc.)
function M.setup_cmp(opts)
  opts = opts or {}

  local cmp_config = opts.cmp_config or {}
  opts.cmp_config = nil

  M.setup(opts)

  local has_cmp, cmp = pcall(require, "cmp")
  if not has_cmp then
    vim.notify("Scalpel: nvim-cmp not found. Install nvim-cmp for completion support.", vim.log.levels.WARN)
    return
  end

  local cmp_helper = require("scalpel.cmp_helper")
  cmp_helper.setup({ cmp_config = cmp_config })
end

M.server = server
M.client = client

return M
