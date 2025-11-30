--[[
Scalpel nvim-cmp Source (Fallback Mode)
=========================================

This is a "passive" nvim-cmp source that provides the AI prediction as a
fallback suggestion when LSP has no matches.

How It Works:
  - Reads the current prediction from state.lua (set by fetcher.lua)
  - Returns it as a single completion item
  - Does NOT trigger new AI requests (that's fetcher.lua's job)

Hybrid Architecture:
  Scalpel uses a dual approach:
  1. **Comparator** (scalpel.comparator) - Boosts existing LSP items
  2. **Source** (this file) - Provides fallback when LSP has nothing

The comparator is the primary mechanism. This source only fires when
the LSP returns no results, ensuring you always have an AI suggestion.

Usage:
  Add to nvim-cmp sources:
    sources = {
      { name = 'scalpel' },  -- Fallback source
      { name = 'nvim_lsp' },
      ...
    }
--]]

local state = require("scalpel.state")

local source = {}

--- Creates a new instance of the Scalpel source
function source.new()
  return setmetatable({}, { __index = source })
end

--- Always available (though may return empty if no prediction)
function source:is_available()
  return true
end

--- Debug identifier for this source
function source:get_debug_name()
  return "scalpel"
end

--- Defines what characters trigger completion
--- Using standard keyword pattern
function source:get_keyword_pattern()
  return [[\\k\\+]]
end

--- Main completion function called by nvim-cmp
--- @param params table nvim-cmp request params
--- @param callback function Callback(result) where result = { items, isIncomplete }
function source:complete(params, callback)
  local prediction = state.prediction
  
  -- No prediction available
  if not prediction or prediction == "" then
    callback({ items = {}, isIncomplete = true })
    return
  end

  -- Return the AI prediction as a single completion item
  local item = {
    label = prediction,
    kind = require("cmp").lsp.CompletionItemKind.Event,
    detail = "Scalpel AI",
    insertText = prediction,
    sortText = "!" .. prediction,  -- "!" prefix makes it sort early
    filterText = prediction,
    documentation = {
      kind = "markdown",
      value = "### Scalpel Prediction\\n" .. prediction
    }
  }

  callback({ items = { item }, isIncomplete = true })
end

return source
