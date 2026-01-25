--[[
Scalpel Shared State
=====================

This module provides a singleton state object that stores the current AI prediction.
Uses a global variable (_G.ScalpelState) to ensure consistency across different
module loading contexts.

Why Global?
-----------
Neovim can load the same plugin from different paths (e.g., via symlinks or when
developing locally). Using a global ensures that all parts of the plugin see the
same state, regardless of how they were required.

State Structure:
  - prediction: string | nil
    The current AI-predicted completion text. Updated by fetcher.lua,
    read by comparator.lua and formatter.lua.
  - typed_prefix: string | nil
    Word fragment before cursor at request time (e.g., "con" when typing "concat").
    Used to compute fill portion for matching.
--]]

-- Initialize global state if it doesn't exist
if not _G.ScalpelState then
	_G.ScalpelState = {
		prediction = nil, -- Current AI prediction
		typed_prefix = nil, -- Word fragment before cursor (e.g., "con")
	}
end

-- Return the global singleton
local M = _G.ScalpelState

return M
