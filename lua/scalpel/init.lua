local config = require("scalpel.config")
local server = require("scalpel.server")
local client = require("scalpel.client")

local M = {}

function M.setup(opts)
  config.setup(opts)
  
  -- Apply keymaps
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

  -- Auto-stop on exit
  vim.api.nvim_create_autocmd("VimLeavePre", {
    callback = function()
      server.stop()
    end,
  })
end

function M.trigger_completion()
  local buf = vim.api.nvim_get_current_buf()
  local win = vim.api.nvim_get_current_win()
  local cursor = vim.api.nvim_win_get_cursor(win)
  local row, col = cursor[1] - 1, cursor[2] -- 0-indexed row

  -- Get all lines
  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  local text = table.concat(lines, "\n")

  -- Calculate cursor byte offset
  -- Note: This is a simplified offset calculation. For multi-byte chars, 
  -- we should be careful. But for now, let's split text at cursor.
  -- A robust way is to use vim.api.nvim_buf_get_text but that's 0.10+ specific for some args.
  
  -- Let's use a simpler approach: get text before and after cursor
  -- In Normal mode, cursor is ON the character. We want to complete AFTER it.
  -- So prefix should include the character under cursor.
  local prefix_lines = vim.api.nvim_buf_get_text(buf, 0, 0, row, col + 1, {})
  local suffix_lines = vim.api.nvim_buf_get_text(buf, row, col + 1, -1, -1, {})
  
  local prefix = table.concat(prefix_lines, "\n")
  local suffix = table.concat(suffix_lines, "\n")

  vim.notify("Requesting completion...", vim.log.levels.INFO)

  client.complete(prefix, suffix, function(res, err)
    if err then
      vim.schedule(function()
        vim.notify("Completion failed: " .. err, vim.log.levels.ERROR)
      end)
      return
    end

    if res and res.completion then
      vim.schedule(function()
        -- Print prompt and completion to messages
        local msg = string.format(
          "--- PROMPT ---\n%s<CURSOR>%s\n\n--- COMPLETION ---\n%s",
          prefix, suffix, res.completion
        )
        vim.notify(msg, vim.log.levels.INFO)
      end)
    end
  end)
end

M.server = server
M.client = client

return M
