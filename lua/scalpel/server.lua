--[[
Scalpel Server Status
=====================

This module provides status checking for the Scalpel server.
The server is managed externally by the user (via `scalpel start/stop` in terminal).

Server Lifecycle (User-Managed):
  - User starts server: `scalpel start` in terminal
  - User stops server: `scalpel stop` in terminal
  - Plugin only checks status and reports

Usage:
  - :ScalpelHealth - Check if server is running
  - :ScalpelStatus - Show detailed server status
--]]

local config = require("scalpel.config")
local M = {}

--- Checks if the server is running by making an HTTP health check
--- @return boolean True if server responds with "OK"
local function ping_server()
  local url = "http://localhost:" .. tostring(config.options.port) .. "/health"
  local result = vim.fn.system({ "curl", "-s", "-m", "2", url })
  return result and result:find("OK") ~= nil
end

--- Gets the current server status
--- @return table Status info
function M.status()
  local running = ping_server()

  return {
    running = running,
    port = config.options.port,
  }
end

--- Performs a health check and notifies the user
--- Called by :ScalpelHealth command
function M.health_check()
  local status = M.status()

  if status.running then
    vim.notify(
      string.format("Scalpel: Server is running on port %d", status.port),
      vim.log.levels.INFO
    )
  else
    vim.notify("Scalpel: Server is not running", vim.log.levels.ERROR)
    vim.notify(
      "To start: run 'scalpel start' in your terminal, then :ScalpelHealth to verify",
      vim.log.levels.INFO
    )
  end
end

return M
