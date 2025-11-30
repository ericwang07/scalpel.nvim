--[[
Scalpel - AI-Powered Code Completion for Neovim
=================================================

Main entry point for the Scalpel plugin. Handles setup, user commands,
keymaps, and exposes core functionality.

Architecture Overview:
  - server.lua: Manages the Rust AI server process
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
  :ScalpelStart    - Start the AI server
  :ScalpelStop     - Stop the AI server
  :ScalpelRestart  - Restart the AI server
  :ScalpelHealth   - Check server health
  :ScalpelComplete - Trigger manual completion

nvim-cmp Integration:
  Add to your nvim-cmp config:
    sorting = {
      comparators = {
        require("scalpel.comparator"),  -- Boost AI predictions
        ...
      }
    },
    sources = {
      { name = 'scalpel' },  -- Fallback source
      { name = 'nvim_lsp' },
      ...
    },
    formatting = {
      format = function(entry, vim_item)
        vim_item = require("scalpel.formatter").format(entry, vim_item)
        return vim_item
      end
    }
--]]

local config = require("scalpel.config")
local server = require("scalpel.server")
local client = require("scalpel.client")
local fetcher = require("scalpel.fetcher")

local M = {}

--- Initializes the plugin
--- @param opts table|nil Configuration options
function M.setup(opts)
  -- Initialize config
  config.setup(opts)
  
  -- Start background fetcher (listens to TextChangedI)
  fetcher.setup()
  
  -- Apply keymaps if configured
  if config.options.keymaps then
    if config.options.keymaps.complete then
      vim.keymap.set("n", config.options.keymaps.complete, function()
        M.trigger_completion()
      end, { desc = "Trigger Scalpel Completion" })
    end
  end

  -- Create user commands
  vim.api.nvim_create_user_command("ScalpelStart", function()
    server.start()
  end, {})

  vim.api.nvim_create_user_command("ScalpelStop", function()
    server.stop()
  end, {})

  vim.api.nvim_create_user_command("ScalpelRestart", function()
    server.restart()
  end, {})
  
  vim.api.nvim_create_user_command("ScalpelHealth", function()
    client.health_check()
  end, {})

  vim.api.nvim_create_user_command("ScalpelComplete", function()
    M.trigger_completion()
  end, {})

  -- Auto-stop server on Neovim exit
  vim.api.nvim_create_autocmd("VimLeavePre", {
    callback = function()
      server.stop()
    end,
  })

  -- Auto-start server on plugin load
  server.start()
  
  -- Register nvim-cmp source (fallback suggestions)
  local has_cmp, cmp = pcall(require, "cmp")
  if has_cmp then
    cmp.register_source("scalpel", require("scalpel.cmp").new())
  end
end

--- Manually triggers a completion request and displays the result
--- This is for debugging/testing - normal usage relies on the auto-fetcher
function M.trigger_completion()
  local buf = vim.api.nvim_get_current_buf()
  local win = vim.api.nvim_get_current_win()
  local cursor = vim.api.nvim_win_get_cursor(win)
  local row, col = cursor[1] - 1, cursor[2]  -- Convert to 0-indexed

  -- Extract text before and after cursor (using col+1 for Normal mode)
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

-- Expose submodules for advanced usage
M.server = server
M.client = client

return M
