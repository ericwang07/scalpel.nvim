--[[
Scalpel Background Fetcher
============================

This module runs in the background and automatically fetches AI predictions
as you type in Insert mode. It uses debouncing and request cancellation to
minimize server load while keeping predictions responsive.

How It Works:
  1. Listens to TextChangedI events (text changes in Insert mode)
  2. Debounces for 100ms to batch rapid keystrokes
  3. Fetches prediction from AI server (via client.lua)
  4. Updates state.prediction on success
  5. Triggers nvim-cmp re-sort to boost matching items

Request Cancellation:
  Uses sequence numbers to ignore stale responses. If you type "abc" then
  quickly change it to "xyz", the "abc" response is discarded even if it
  arrives later. This prevents UI jitter from out-of-order responses.

Performance:
  - 100ms debounce: Balances responsiveness vs server load
  - Logical cancellation: Old responses ignored (not true HTTP cancellation)
  - Non-blocking: LSP completions show immediately, AI boosts them later
--]]

local client = require("scalpel.client")
local state = require("scalpel.state")
local config = require("scalpel.config")

local M = {}

-- Debounce timer for batching keystrokes
local timer = nil

-- Request sequence tracking for cancellation
-- Increments with each new request; responses check if they're still current
local request_seq = 0

--- Sets up autocommands for background fetching
function M.setup()
  local group = vim.api.nvim_create_augroup("ScalpelFetcher", { clear = true })
  
  vim.api.nvim_create_autocmd("TextChangedI", {
    group = group,
    callback = function()
      M.on_text_changed()
    end,
  })
end

--- Debounced handler for text changes
--- Resets the 100ms timer on each keystroke
function M.on_text_changed()
  -- Cancel previous timer if still waiting
  if timer then
    timer:stop()
    timer:close()
  end
  
  -- Start new 100ms countdown
  timer = vim.loop.new_timer()
  timer:start(100, 0, vim.schedule_wrap(function()
    timer:stop()
    timer:close()
    timer = nil
    
    M.fetch_prediction()
  end))
end

--- Fetches a prediction from the AI server
--- Extracts context (prefix/suffix), makes async request, updates state
function M.fetch_prediction()
  local buf = vim.api.nvim_get_current_buf()
  local win = vim.api.nvim_get_current_win()
  
  -- Safety checks
  if not vim.api.nvim_buf_is_valid(buf) then return end
  local mode = vim.api.nvim_get_mode().mode
  if mode:sub(1, 1) ~= "i" then return end  -- Only in Insert mode

  local cursor = vim.api.nvim_win_get_cursor(win)
  local row, col = cursor[1] - 1, cursor[2]  -- Convert to 0-indexed
  
  -- Extract text before and after cursor
  local prefix_lines = vim.api.nvim_buf_get_text(buf, 0, 0, row, col, {})
  local suffix_lines = vim.api.nvim_buf_get_text(buf, row, col, -1, -1, {})
  
  local prefix = table.concat(prefix_lines, "\n")
  local suffix = table.concat(suffix_lines, "\n")
  local filetype = vim.bo[buf].filetype

  -- Assign sequence number to this request
  request_seq = request_seq + 1
  local current_seq = request_seq

  -- Make async request to AI server
  client.complete(prefix, suffix, filetype, function(res, err)
    -- Ignore stale responses (user kept typing, newer request in flight)
    if current_seq ~= request_seq then
      return
    end

    if not err and res and res.completion then
      -- Update shared state with new prediction
      state.prediction = res.completion
      
      -- Trigger nvim-cmp to re-sort items with new prediction
      -- This causes the comparator to run and boost matching items
      local current_mode = vim.api.nvim_get_mode().mode
      if current_mode:sub(1, 1) == "i" then
        require("cmp").complete()
      end
    else
      -- Clear prediction on error
      state.prediction = nil
    end
  end)
end

return M
