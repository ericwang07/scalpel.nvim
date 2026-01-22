local M = {}

M.pass_count = 0
M.fail_count = 0

function M.assert_eq(name, actual, expected)
  if actual == expected then
    print("PASS: " .. name)
    M.pass_count = M.pass_count + 1
  else
    print("FAIL: " .. name .. " (expected " .. tostring(expected) .. ", got " .. tostring(actual) .. ")")
    M.fail_count = M.fail_count + 1
  end
end

function M.assert_true(name, actual)
  if actual then
    print("PASS: " .. name)
    M.pass_count = M.pass_count + 1
  else
    print("FAIL: " .. name .. " (expected true, got " .. tostring(actual) .. ")")
    M.fail_count = M.fail_count + 1
  end
end

function M.assert_gt(name, actual, expected)
  if actual > expected then
    print("PASS: " .. name)
    M.pass_count = M.pass_count + 1
  else
    print("FAIL: " .. name .. " (expected > " .. tostring(expected) .. ", got " .. tostring(actual) .. ")")
    M.fail_count = M.fail_count + 1
  end
end

function M.assert_nil(name, actual)
  if actual == nil then
    print("PASS: " .. name)
    M.pass_count = M.pass_count + 1
  else
    print("FAIL: " .. name .. " (expected nil, got " .. tostring(actual) .. ")")
    M.fail_count = M.fail_count + 1
  end
end

function M.assert_match(name, actual, pattern)
  if string.find(actual, pattern) then
    print("PASS: " .. name)
    M.pass_count = M.pass_count + 1
  else
    print("FAIL: " .. name .. " (expected to contain " .. pattern .. ", got " .. tostring(actual) .. ")")
    M.fail_count = M.fail_count + 1
  end
end

function M.reset()
  M.pass_count = 0
  M.fail_count = 0
end

function M.report(test_name)
  print("=== " .. test_name .. " Complete ===")
  print("Passed: " .. M.pass_count .. ", Failed: " .. M.fail_count)
end

function M.exit_if_failed()
  if M.fail_count > 0 then
    os.exit(1)
  end
end

return M
