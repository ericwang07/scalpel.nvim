--[[
Scalpel Server Manager
=======================

Manages the lifecycle of the local Rust AI server process.
Handles starting, stopping, and restarting the server.

The server is a separate Rust binary (built from server/) that hosts
the AI model and provides the HTTP /complete endpoint.

Server Lifecycle:
  - Auto-starts when plugin loads (via init.lua)
  - Auto-stops on Neovim exit (VimLeavePre)
  - Can be manually controlled via :ScalpelStart/:ScalpelStop/:ScalpelRestart

Exit Codes:
  - 0: Clean shutdown
  - 143: SIGTERM (expected when we call stop()) - Ignored
  - Other non-zero: Unexpected failure (user should check server logs)

Binary Discovery:
  1. If config.binary_path is set, use that
  2. Otherwise, look for server/target/release/scalpel relative to plugin root
  3. If not found, show error (user needs to build the server first)
--]]

local config = require("scalpel.config")
local M = {}

-- Current job ID (nil if not running)
M.job_id = nil

-- Flag to indicate restart in progress
M.is_restarting = false

--- Finds the Scalpel server binary
--- @return string|nil Path to binary, or nil if not found
local function get_binary_path()
  if config.options.binary_path then
    return config.options.binary_path
  end
  
  -- Auto-detect: Look in server/target/release/ relative to plugin root
  -- debug.getinfo gets the current file path, then we go up 3 levels
  local plugin_root = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":h:h:h")
  local bin_path = plugin_root .. "/server/target/release/scalpel"
  
  if vim.fn.executable(bin_path) == 1 then
    return bin_path
  end
  
  return nil
end

--- Starts the Scalpel server
function M.start()
  -- Don't start if already running
  if M.job_id then
    return
  end
  
  -- Find the binary
  local bin = get_binary_path()
  if not bin then
    vim.notify(
      "Scalpel server binary not found. Please build it or configure 'binary_path'.",
      vim.log.levels.ERROR
    )
    return
  end
  
  local cmd = { bin }
  
  local job_opts = {
    env = {
      SCALPEL_PORT = tostring(config.options.port),
    },
    detach = false,
    
    -- Server stdout/stderr are currently ignored
    -- Uncomment for debugging server issues
    on_stdout = function(_, data)
      -- for _, line in ipairs(data or {}) do
      --   if line ~= "" then
      --     print("[Scalpel] " .. line)
      --   end
      -- end
    end,
    
    on_stderr = function(_, data)
      -- for _, line in ipairs(data or {}) do
      --   if line ~= "" then
      --     print("[Scalpel] " .. line)
      --   end
      -- end
    end,
    
    on_exit = function(_, code)
      M.job_id = nil
      
      -- Handle restart flag
      if M.is_restarting then
        M.is_restarting = false
        vim.schedule(function()
          M.start()
        end)
        return
      end
      
      -- Exit code 143 is SIGTERM (expected when we call stop())
      -- All other non-zero codes are unexpected
      if code ~= 0 and code ~= 143 then
        -- Silently fail - user can check via :ScalpelHealth if needed
      end
    end,
  }
  
  -- Start the job
  M.job_id = vim.fn.jobstart(cmd, job_opts)
  if M.job_id <= 0 then
    vim.notify("Failed to start Scalpel server", vim.log.levels.ERROR)
    M.job_id = nil
  end
end

--- Stops the Scalpel server
function M.stop()
  if M.job_id then
    vim.fn.jobstop(M.job_id)
    M.job_id = nil
  end
end

--- Restarts the Scalpel server
function M.restart()
  if M.job_id then
    M.is_restarting = true
    M.stop()
  else
    M.start()
  end
end

return M
