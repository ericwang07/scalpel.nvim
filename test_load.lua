package.path = package.path .. ";./lua/?.lua"

local function try_load(module)
  local ok, err = pcall(require, module)
  if ok then
    print("PASS: " .. module)
  else
    print("FAIL: " .. module .. " - " .. tostring(err))
  end
end

print("Verifying Lua modules...")
try_load("scalpel.config")
try_load("scalpel.validator")
try_load("scalpel.client")
try_load("scalpel.cmp")
try_load("scalpel.init")
print("Done.")
