local config = require("scalpel.config")
local curl = require("plenary.curl")
local validator = require("scalpel.validator")
local M = {}

-- Simple curl wrapper
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
      if response.status ~= 200 then
        -- vim.notify("Scalpel request failed: " .. response.body, vim.log.levels.ERROR)
        if callback then callback(nil, "HTTP " .. response.status .. ": " .. response.body) end
        return
      end

      local ok, decoded = pcall(vim.fn.json_decode, response.body)
      if not ok then
        if callback then callback(nil, "JSON decode error") end
        return
      end

      if callback then
        callback(decoded, nil)
      end
    end),
  })
end

local debounce_timer = nil

function M.complete(prefix, suffix, filetype, callback)
  -- Cancel previous timer if it exists
  if debounce_timer then
    debounce_timer:stop()
    debounce_timer:close()
    debounce_timer = nil
  end

  -- Create new timer
  debounce_timer = vim.loop.new_timer()
  debounce_timer:start(300, 0, vim.schedule_wrap(function()
    debounce_timer:stop()
    debounce_timer:close()
    debounce_timer = nil

    local body = {
      prefix = prefix,
      suffix = suffix,
    }
    
    M.request("POST", "/complete", body, function(response, err)
      if err then
        callback(nil, err)
        return
      end
  
      local completion = response.completion
      local full_code = prefix .. completion .. suffix
      
      if validator.validate(full_code, filetype) then
        callback(response, nil)
      else
        -- vim.notify("Scalpel: Invalid syntax generated, discarding.", vim.log.levels.WARN)
        callback(nil, "Invalid syntax")
      end
    end)
  end))
end

return M
