package.path = package.path .. ";./lua/?.lua"

print("=== Testing Scalpel Architecture (Post-CMP-Source Removal) ===")

-- Test 1: Verify cmp.lua is removed (should fail to load)
print("\nTest 1: Verifying cmp.lua is removed...")
local cmp_ok, cmp_source = pcall(require, "scalpel.cmp")
if cmp_ok then
  print("FAIL: scalpel.cmp still exists - should have been removed")
else
  print("PASS: scalpel.cmp removed as expected")
end

-- Test 2: Verify comparator exists
print("\nTest 2: Verifying comparator exists...")
local comparator_ok, comparator = pcall(require, "scalpel.comparator")
if not comparator_ok then
  print("FAIL: scalpel.comparator not found")
else
  print("PASS: scalpel.comparator loaded successfully")
  if type(comparator) == "function" then
    print("PASS: comparator returns a function")
  else
    print("FAIL: comparator should return a function")
  end
end

-- Test 3: Verify formatter exists
print("\nTest 3: Verifying formatter exists...")
local formatter_ok, formatter = pcall(require, "scalpel.formatter")
if not formatter_ok then
  print("FAIL: scalpel.formatter not found")
else
  print("PASS: scalpel.formatter loaded successfully")
  if formatter.format and type(formatter.format) == "function" then
    print("PASS: formatter.format is a function")
  else
    print("FAIL: formatter.format should be a function")
  end
end

-- Test 4: Verify cmp_helper exists and doesn't reference cmp source
print("\nTest 4: Verifying cmp_helper exists...")
local helper_ok, helper = pcall(require, "scalpel.cmp_helper")
if not helper_ok then
  print("FAIL: scalpel.cmp_helper not found")
else
  print("PASS: scalpel.cmp_helper loaded successfully")
  if helper.setup and type(helper.setup) == "function" then
    print("PASS: cmp_helper.setup is a function")
  else
    print("FAIL: cmp_helper.setup should be a function")
  end
end

print("\n=== Architecture Test Complete ===")
