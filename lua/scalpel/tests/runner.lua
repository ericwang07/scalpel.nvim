package.path = package.path .. ";./lua/?.lua"

local a = require("scalpel.tests.helpers")

local test_files = {
  "test_matcher",
  "test_config",
  "test_state",
  "test_comparator",
  "test_formatter",
  "test_client",
  "test_fetcher",
}

print("=========================================")
print("Scalpel Test Suite")
print("=========================================")

local total_pass = 0
local total_fail = 0

for _, test_name in ipairs(test_files) do
  a.reset()

  print("")
  print("Running: " .. test_name .. ".lua")

  local ok, err = pcall(require, "scalpel.tests." .. test_name)

  if not ok then
    print("FAILED: " .. test_name .. ".lua")
    print("Error: " .. tostring(err))
    total_fail = total_fail + 1
  else
    total_pass = total_pass + a.pass_count
    total_fail = total_fail + a.fail_count
  end
end

print("")
print("=========================================")
print("Test Summary")
print("=========================================")
print("Total Passed: " .. total_pass)
print("Total Failed: " .. total_fail)
print("=========================================")

if total_fail > 0 then
  os.exit(1)
end
