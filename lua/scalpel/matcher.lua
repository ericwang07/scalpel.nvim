--[[
Scalpel Fuzzy Matcher
=====================

This module provides fuzzy matching logic for comparing AI predictions
with completion candidates. Used by both the comparator (for sorting)
and formatter (for visual indicators).

Scoring System:
  3 = Exact match (e.g., "concat" == "concat")
  2 = Prefix match (e.g., "string" starts with "st")
  1 = Suffix match or Substring match (e.g., "string" ends with "ring" or contains "tri")
  0 = No match

Minimum Length:
  To reduce noise from short predictions (like single letters), we require
  at least 3 characters for prefix/suffix/substring matches. Exact matches
  have no length requirement.

Priority:
  Prefix matches are prioritized over suffix matches to prefer full identifiers.
  When typing "st", predictions like "ring" will boost "string" (prefix match)
  over other completions that might only match by suffix.

Example:
  prediction="tab", candidate="table" -> Score 2 (prefix)
  prediction="ta", candidate="table"  -> Score 0 (too short)
  prediction="ring", candidate="string" -> Score 2 (prefix - preferred)
  prediction="ring", candidate="spring" -> Score 1 (suffix - lower priority)
  prediction="cat", candidate="concat" -> Score 1 (substring)
--]]

local M = {}

--- Calculates a fuzzy match score between a candidate and prediction
--- @param candidate string The completion item's label or insertText
--- @param prediction string The AI's predicted text
--- @return number Score from 0-3 (0=no match, 3=exact match)
function M.score(candidate, prediction)
  -- Handle nil/empty inputs
  if not candidate or not prediction then return 0 end
  if candidate == "" or prediction == "" then return 0 end
  
  -- Exact match (highest priority, no length requirement)
  if candidate == prediction then return 3 end
  
  -- Prefix match (highest priority, requires >= 3 chars)
  if #prediction > 3 and #candidate > 3 then
    if vim.startswith(candidate, prediction) or vim.startswith(prediction, candidate) then
      return 2  -- Priority over suffix matches
    end
    
    -- Suffix match (lower priority)
    if vim.endswith(candidate, prediction) or vim.endswith(prediction, candidate) then
      return 1  -- Lower than prefix matches
    end
  end

  -- Substring match (requires >= 3 chars, lowest priority)
  -- Note: string.find(..., 1, true) does literal search (not pattern matching)
  if #prediction > 3 and #candidate > 3 then
    if string.find(candidate, prediction, 1, true) or string.find(prediction, candidate, 1, true) then
      return 1
    end
  end
  
  -- No match
  return 0
end

return M
