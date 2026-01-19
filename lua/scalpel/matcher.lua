--[[
Scalpel Fuzzy Matcher
==================== 

This module provides fuzzy matching logic for comparing AI predictions
with completion candidates. Used by both the comparator (for sorting)
and formatter (for visual indicators).

Scoring System (highest to lowest):
  3 = Full identifier match: prefix + prediction == candidate
      (e.g., prefix="st", prediction="ring", candidate="string")
  3 = Exact match (e.g., "concat" == "concat")
  2 = Prefix match (e.g., "string" starts with "st" or vice versa)
  0 = Suffix match, Substring match, or No match

Full Identifier Priority:
  When the user's input (prefix) plus the AI prediction forms a complete
  identifier from the completions list, that completion gets highest priority (3).
  This ensures completions like "string" appear when typing "st" and AI predicts "ring",
  rather than showing partial matches like "ring" or unrelated suffix matches like "spring".

Minimum Length:
  To reduce noise from short predictions (like single letters), we require
  at least 3 characters for prefix matches. Full identifier and exact matches
  have no length requirement.

Example:
  prefix="st", prediction="ring", candidate="string" -> Score 3 (full identifier)
  prefix="", prediction="ring", candidate="ring"    -> Score 3 (exact match)
  prediction="tab", candidate="table"               -> Score 2 (prefix)
  prediction="ring", candidate="string"             -> Score 0 (suffix - NOT served)
  prediction="cat", candidate="concat"              -> Score 0 (substring - NOT served)
  prediction="ab", candidate="abc"                  -> Score 0 (too short)
--]]

local M = {}

--- Calculates a fuzzy match score between a candidate and prediction
--- @param candidate string The completion item's label or insertText
--- @param prediction string The AI's predicted text
--- @param prefix string|nil Text before cursor (user's input)
--- @return number Score from 0-3 (0=no match, 3=exact match)
function M.score(candidate, prediction, prefix)
  -- Handle nil/empty inputs
  if not candidate or not prediction then return 0 end
  if candidate == "" or prediction == "" then return 0 end
  
  -- Exact match (highest priority, no length requirement)
  if candidate == prediction then return 3 end

  -- Full identifier match: prefix + prediction == candidate
  -- This ensures we only serve completions where user input + AI prediction = full identifier
  -- Example: prefix="st", prediction="ring", candidate="string" -> match!
  if prefix and prefix ~= "" then
    local full_identifier = prefix .. prediction
    if candidate == full_identifier then
      return 3  -- Same priority as exact match
    end
  end

  -- Prefix match (highest priority for non-exact/non-full matches, requires >= 3 chars)
  -- Suffix and substring matches are intentionally NOT included - we only serve
  -- exact matches, full identifier matches, or prefix matches
  if #prediction > 3 and #candidate > 3 then
    if vim.startswith(candidate, prediction) or vim.startswith(prediction, candidate) then
      return 2  -- Prefix match priority
    end
  end
  
  -- No match
  return 0
end

return M
