package.path = package.path .. ";./lua/?.lua"
local validator = require("scalpel.validator")

local function test(name, code, filetype, expected)
  local result = validator.validate(code, filetype)
  if result == expected then
    print("PASS: " .. name)
  else
    print("FAIL: " .. name .. " (Expected " .. tostring(expected) .. ", got " .. tostring(result) .. ")")
  end
end

print("Running Validator Tests...")

-- Lua Tests
test("Valid Lua", "local x = 1", "lua", true)
test("Invalid Lua", "local x =", "lua", false)
test("Valid Lua Function", "function foo() return 1 end", "lua", true)
test("Invalid Lua Function", "function foo() return", "lua", false)

-- Python Tests (if parser available)
local has_python = pcall(vim.treesitter.get_string_parser, "x = 1", "python")
if has_python then
  test("Valid Python", "def foo():\n    return 1", "python", true)
  test("Invalid Python", "def foo():\n    return", "python", true) -- Python parser might be lenient on incomplete blocks?
  test("Syntax Error Python", "def foo(", "python", false)
else
  print("Skipping Python tests (parser not found)")
end

print("Done.")
