local config = require("scalpel.config")
local M = {}

-- Simple curl wrapper
function M.request(method, endpoint, body, callback)
  local url = "http://127.0.0.1:" .. config.options.port .. endpoint
  
  local cmd = { "curl", "-X", method, url }
  
  if body then
    table.insert(cmd, "-H")
    table.insert(cmd, "Content-Type: application/json")
    table.insert(cmd, "-d")
    table.insert(cmd, vim.json.encode(body))
  end

  vim.system(cmd, { text = true }, function(obj)
    if obj.code ~= 0 then
      local err_msg = (obj.stderr and obj.stderr ~= "") and obj.stderr or obj.stdout
      if err_msg == "" then err_msg = "Unknown curl error (exit code " .. obj.code .. ")" end
      
      vim.schedule(function()
        vim.notify("Scalpel request failed: " .. err_msg, vim.log.levels.ERROR)
      end)
      if callback then callback(nil, err_msg) end
      return
    end

    local decoded_ok, decoded = pcall(vim.json.decode, obj.stdout)
    if not decoded_ok then
       -- It might not be JSON, just return text
       if callback then callback(obj.stdout, nil) end
    else
       if callback then callback(decoded, nil) end
    end
  end)
end

function M.health_check()
  M.request("GET", "/health", nil, function(res, err)
    if err then
      vim.notify("Scalpel server is unreachable", vim.log.levels.WARN)
    else
      vim.notify("Scalpel server is healthy: " .. vim.inspect(res), vim.log.levels.INFO)
    end
  end)
end

function M.complete(prefix, suffix, callback)
  local body = {
    prefix = prefix,
    suffix = suffix,
  }
  M.request("POST", "/complete", body, callback)
end

return M
