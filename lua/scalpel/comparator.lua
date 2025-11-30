--[[
Scalpel nvim-cmp Comparator
=============================

This comparator integrates with nvim-cmp's sorting pipeline to boost
completion items that match the AI's prediction.

How It Works:
  1. Checks if there's an active AI prediction
  2. Scores each completion item using matcher.lua (0-3)
  3. Items with higher scores are sorted first
  4. Returns nil if no match, letting other comparators decide

This creates the "boosting" effect where AI-predicted items jump to
the top of the completion menu.

Usage:
  Add to nvim-cmp sorting.comparators:
    sorting = {
      comparators = {
        require("scalpel.comparator"),  -- Add first for highest priority
        cmp.config.compare.offset,
        ...
      }
    }
--]]

local state = require("scalpel.state")
local matcher = require("scalpel.matcher")

local M = {}

--- Comparator function for nvim-cmp sorting
--- @param entry1 table First completion entry
--- @param entry2 table Second completion entry
--- @return boolean|nil true if entry1 should come before entry2, nil to defer to next comparator
M.score = function(entry1, entry2)
  local prediction = state.prediction
  
  -- No prediction means we have nothing to boost
  if not prediction or prediction == "" then
    return nil
  end

  -- Helper to compute the best score for an entry
  local function get_score(entry)
    local label = entry.completion_item.label
    local insert_text = entry.completion_item.insertText or label
    
    -- Check both label and insertText, use highest score
    return math.max(
      matcher.score(label, prediction), 
      matcher.score(insert_text, prediction)
    )
  end

  local score1 = get_score(entry1)
  local score2 = get_score(entry2)

  -- If neither matches the prediction, let other comparators decide
  if score1 == 0 and score2 == 0 then
    return nil
  end
  
  -- Higher score wins (comes first in the list)
  if score1 > score2 then
    return true
  elseif score1 < score2 then
    return false
  end

  -- Equal scores (both match equally well) - let other comparators decide
  return nil
end

-- Return the function directly for use in cmp config
return M.score
