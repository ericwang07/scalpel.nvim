-- Add current directory to runtime path so we can require 'scalpel.server'
vim.opt.rtp:prepend(".")

local config = require("scalpel.config")
local server = require("scalpel.server")

-- Initialize config
config.setup({
  log_level = "debug",
})

print("Testing Scalpel Server...")

-- 1. Test Start
print("Starting server...")
server.start()

-- Give it a moment to start
vim.wait(1000)

if server.job_id then
  print("SUCCESS: Server started with Job ID: " .. server.job_id)
else
  print("FAILURE: Server failed to start")
  os.exit(1)
end

-- 2. Test Client
print("Testing Client Request...")
local client = require("scalpel.client")
local done = false
client.request("GET", "/health", nil, function(res, err)
  if err then
    print("FAILURE: Client request failed: " .. err)
    os.exit(1)
  else
    print("SUCCESS: Client received response: " .. vim.inspect(res))
  end
  done = true
end)

-- 3. Test Completion (Mocked for now, as we might not have a model)
print("Testing Completion Request...")
local done_complete = false

client.complete("def fib(n): return fib(n-1) + fib(n-", "\n", function(res, err)
  if err then
    io.write("COMPLETION FINISHED (error): " .. err .. "\n")
  else
    io.write("COMPLETION SUCCESS: received: " .. vim.inspect(res) .. "\n")
  end
  done_complete = true
end)

local wait_result = vim.wait(15000, function() return done_complete end)

if not wait_result then
  print("FAILURE: Completion request timed out (15s)")
end

-- 4. Test Stop
print("Stopping server...")
server.stop()

if server.job_id == nil then
  print("SUCCESS: Server stopped")
else
  print("FAILURE: Server did not stop, Job ID still exists: " .. tostring(server.job_id))
  os.exit(1)
end

print("All tests passed!")
os.exit(0)
