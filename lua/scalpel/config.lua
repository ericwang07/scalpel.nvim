--[[
Scalpel Configuration
======================

Manages plugin configuration with sensible defaults.
Users can override these by passing options to setup().

Configuration Options:
  - binary_path: string | nil
    Path to the Scalpel Rust server binary. If nil, automatically
    searches in server/target/release/ relative to plugin root.
  
  - port: number (default: 3000)
    Port for the local AI server to listen on.
  
  - keymaps: table
    Optional keybindings for triggering manual completion.
    Example: { complete = "<C-k>" }

Usage:
  require("scalpel").setup({
    port = 8080,
    keymaps = { complete = "<C-k>" }
  })
--]]

local M = {}

--- Default configuration
M.defaults = {
  -- Binary path (nil = auto-detect)
  binary_path = nil,
  
  -- Server port
  port = 3000,
  
  -- Keymaps (nil = disabled)
  keymaps = {
    complete = nil,
  },
}

--- Active configuration (set by setup())
M.options = {}

--- Initializes configuration by merging user options with defaults
--- @param opts table|nil User configuration options
function M.setup(opts)
  M.options = vim.tbl_deep_extend("force", M.defaults, opts or {})
  
  -- Construct server URL from port
  M.options.server_url = "http://127.0.0.1:" .. M.options.port
end

return M
