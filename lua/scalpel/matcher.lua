--[[
Scalpel Matcher
================

This module provides matching logic for comparing AI predictions
with completion candidates. Used by both the comparator (for sorting)
and formatter (for visual indicators).

Fill Comparison:
  When typed_prefix is provided, we compare the "fill" portions:
  - If user typed "con" and candidate is "concat", candidate fill is "cat"
  - If AI predicted "cat", we compare "cat" == "cat" -> exact match

Scoring System:
  1 = Exact match
  0 = No match

Example:
  typed_prefix="con", candidate="concat", prediction="cat"
  -> candidate_fill="cat", matches prediction exactly -> Score 1
--]]

local M = {}

--- Checks for exact match between two fill strings
--- @param candidate_fill string The candidate's fill portion (after typed prefix)
--- @param prediction string The AI's predicted text
--- @return number 1 if exact match, 0 otherwise
function M.score_fill(candidate_fill, prediction)
	-- Handle non-string inputs
	if type(candidate_fill) ~= "string" or type(prediction) ~= "string" then
		return 0
	end

	-- Handle nil/empty inputs
	if not candidate_fill or not prediction then
		return 0
	end
	if candidate_fill == "" or prediction == "" then
		return 0
	end

	-- Exact match only
	if candidate_fill == prediction then
		return 1
	end

	return 0
end

--- Calculates match score between a candidate and prediction
--- @param candidate string The completion item's label or insertText
--- @param prediction string The AI's predicted text
--- @param typed_prefix string|nil The word fragment typed before cursor
--- @return number 1 if exact match, 0 otherwise
function M.score(candidate, prediction, typed_prefix)
	-- Handle non-string inputs (return 0 for non-strings)
	if type(candidate) ~= "string" or type(prediction) ~= "string" then
		return 0
	end

	-- Handle nil/empty inputs
	if not candidate or not prediction then
		return 0
	end
	if candidate == "" or prediction == "" then
		return 0
	end

	-- If typed_prefix provided and candidate starts with it,
	-- compare only the fill portions
	if typed_prefix and #typed_prefix > 0 and vim.startswith(candidate, typed_prefix) then
		local candidate_fill = candidate:sub(#typed_prefix + 1)
		return M.score_fill(candidate_fill, prediction)
	end

	-- Fallback: no typed_prefix or candidate doesn't start with it
	-- Use direct comparison (original behavior)
	return M.score_fill(candidate, prediction)
end

return M
