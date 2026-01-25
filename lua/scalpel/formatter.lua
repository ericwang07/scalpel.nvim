--[[
Scalpel nvim-cmp Formatter
===========================

This formatter adds a visual indicator (⚡) to completion items that match
the AI's prediction, making it easy to see which items are "boosted".
--]]

local state = require("scalpel.state")
local matcher = require("scalpel.matcher")
local config = require("scalpel.config")

local M = {}

M.ICON = "⚡"

--- Formats a completion item, adding visual indicator if it matches the prediction
--- @param entry table nvim-cmp entry object
--- @param vim_item table nvim-cmp vim_item object (modify in-place)
--- @return table Modified vim_item
function M.format(entry, vim_item)
	-- Skip if plugin is disabled
	if not config.options.enabled then
		return vim_item
	end

	local prediction = state.prediction
	local typed_prefix = state.typed_prefix

	local label = entry.completion_item.label
	local insert_text = entry.completion_item.insertText or label

	-- Check if this item matches the prediction
	local score = math.max(
		matcher.score(label, prediction, typed_prefix),
		matcher.score(insert_text, prediction, typed_prefix)
	)

	if prediction and score > 0 then
		-- This item matches the AI prediction - mark it with lightning
		vim_item.kind = (vim_item.kind or "") .. " " .. M.ICON .. " "
	else
		-- No match - add padding to keep menu width stable
		vim_item.kind = (vim_item.kind or "") .. "   "
	end

	return vim_item
end

return M
