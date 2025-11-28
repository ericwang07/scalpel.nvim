package.path = package.path .. ";./lua/?.lua"

-- Mock vim.notify and vim.schedule since we are running in headless mode
vim.notify = function(msg, level)
  print("[NOTIFY] " .. msg)
end
vim.schedule = function(cb) cb() end
vim.fn = {
  json_encode = vim.json.encode,
  json_decode = vim.json.decode
}
-- Mock vim.bo for filetype
vim.bo = {
    [0] = { filetype = "lua" }
}

-- Mock plenary.curl (since it might not be in path, we need to ensure it is or mock it)
-- Actually, let's assume the user runs this with `nvim -l` which might have access to plugins if configured, 
-- but usually `nvim -l` is isolated. 
-- To be safe, let's try to require client. If it fails due to plenary, we know we need to point to it.
-- But wait, the user's environment has plenary.
-- Let's try to use the actual client.

local client = require("scalpel.client")
local config = require("scalpel.config")

-- Setup config (mocking setup)
config.setup({
    port = 3000
})

print("Testing Scalpel Client...")
print("Server URL: " .. config.options.server_url)

local prefix = "local x = "
local suffix = "\nprint(x)"
local filetype = "lua"

print("Sending request...")
client.complete(prefix, suffix, filetype, function(res, err)
    if err then
        print("ERROR: " .. tostring(err))
    elseif res then
        print("SUCCESS: Got completion")
        print("Completion: '" .. tostring(res.completion) .. "'")
    else
        print("FAILURE: No response or empty completion")
    end
end)

-- Wait a bit for async (curl)
vim.wait(2000, function() return false end)
print("Done.")
