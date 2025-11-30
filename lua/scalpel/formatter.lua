--[[
Scalpel nvim-cmp Formatter
============================

This formatter adds a visual indicator (⚡) to completion items that match
the AI's prediction, making it easy to see which items are "boosted".

How It Works:
  1. Scores the completion item against the current prediction
  2. If score > 0, appends " ⚡" to the kind field
  3. If score = 0, appends "  " (padding) to maintain stable menu width

The padding is important to prevent the menu from "jumping" when the
lightning bolt appears/disappears as you type.

Usage:
  Add to nvim-cmp formatting:
    formatting = {
      format = function(entry, vim_item)
        vim_item = require("scalpel.formatter").format(entry, vim_item)
        -- Can chain other formatters here (e.g., lspkind)
        return vim_item
      end
    }
--]]

local state = require("scalpel.state")
local matcher = require("scalpel.matcher")

local M = {}

--- Formats a completion item, adding visual indicator if it matches the prediction
--- @param entry table nvim-cmp entry object
--- @param vim_item table nvim-cmp vim_item object (modify in-place)
--- @return table Modified vim_item
function M.format(entry, vim_item)
  local prediction = state.prediction

  local label = entry.completion_item.label
  local insert_text = entry.completion_item.insertText or label
  
  -- Check if this item matches the prediction
  local score = math.max(
    matcher.score(label, prediction), 
    matcher.score(insert_text, prediction)
  )
  
  if prediction and score > 0 then
    -- This item matches the AI prediction - mark it with lightning
    vim_item.kind = (vim_item.kind or "") .. " ⚡"
  else
    -- No match - add padding to keep menu width stable
    -- The lightning bolt is ~2-3 chars wide, so "  " (two spaces) compensates
    vim_item.kind = (vim_item.kind or "") .. "  "
  end

  return vim_item
end

return M
