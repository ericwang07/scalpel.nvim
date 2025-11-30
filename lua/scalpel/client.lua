--[[
Scalpel HTTP Client
====================

This module handles all HTTP communication with the local Scalpel AI server.
It provides a thin wrapper around plenary.curl for making JSON requests.

Main Functions:
  - request(method, endpoint, body, callback)
    Generic HTTP request wrapper with JSON encoding/decoding
  
  - complete(prefix, suffix, filetype, callback)
    Request a code completion from the AI server
    Callback signature: function(response, error)
      - response: { completion: string, ... }
      - error: string | nil

Architecture Notes:
  - No debouncing here - that's handled by fetcher.lua
  - Errors are silently ignored to avoid spamming the user
  - All callbacks are wrapped in vim.schedule for thread safety
--]]

local config = require("scalpel.config")
local curl = require("plenary.curl")

local M = {}

--- Makes an HTTP request to the Scalpel server
--- @param method string HTTP method (e.g., "POST", "GET")
--- @param endpoint string API endpoint (e.g., "/complete")
--- @param body table Request body (will be JSON encoded)
--- @param callback function Callback(response, error)
function M.request(method, endpoint, body, callback)
  local url = config.options.server_url .. endpoint
  
  curl.request({
    url = url,
    method = method,
    body = vim.fn.json_encode(body),
    headers = {
      ["Content-Type"] = "application/json",
    },
    callback = vim.schedule_wrap(function(response)
      -- Non-200 responses are treated as errors
      if response.status ~= 200 then
        if callback then 
          callback(nil, "HTTP " .. response.status .. ": " .. response.body) 
        end
        return
      end

      -- Attempt to decode JSON response
      local ok, decoded = pcall(vim.fn.json_decode, response.body)
      if not ok then
        -- Silently fail on decode errors to avoid spam
        -- This handles transient issues like partial responses
        return
      end

      if callback then
        callback(decoded, nil)
      end
    end),
  })
end

--- Requests a code completion from the AI server
--- @param prefix string Code before cursor
--- @param suffix string Code after cursor
--- @param filetype string Neovim filetype (e.g., "lua", "python")
--- @param callback function Callback(response, error) where response has { completion: string }
function M.complete(prefix, suffix, filetype, callback)
  local body = {
    prefix = prefix,
    suffix = suffix,
  }
  
  M.request("POST", "/complete", body, function(response, err)
    if err then
      callback(nil, err)
      return
    end

    -- response.completion contains the AI's predicted text
    callback(response, nil)
  end)
end

return M
