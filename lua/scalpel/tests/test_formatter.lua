package.path = package.path .. ";./lua/?.lua"

package.loaded["scalpel.state"] = nil
_G.ScalpelState = { prediction = nil }

local state = require("scalpel.state")
local formatter = require("scalpel.formatter")
local a = require("scalpel.tests.helpers")

print("=== Formatter Tests ===")

local function make_entry(label, insertText)
  insertText = insertText or label
  return {
    completion_item = {
      label = label,
      insertText = insertText,
    }
  }
end

local function format_entry(entry, prediction)
  state.prediction = prediction
  local vim_item = { kind = "Text" }
  return formatter.format(entry, vim_item)
end

a.assert_match("ICON constant", formatter.ICON, ".")

local result = format_entry(make_entry("function"), "function")
a.assert_match("matching gets icon", result.kind, " " .. formatter.ICON .. " ")

result = format_entry(make_entry("other"), "function")
a.assert_match("non-matching gets padding", result.kind, "   ")

state.prediction = ""
result = format_entry(make_entry("test"), "")
a.assert_match("empty prediction padding", result.kind, "   ")

state.prediction = nil
result = format_entry(make_entry("test"), nil)
a.assert_match("nil prediction padding", result.kind, "   ")

result = format_entry(make_entry("function"), "func")
a.assert_match("prefix match gets icon", result.kind, " " .. formatter.ICON .. " ")

result = format_entry(make_entry("test_func"), "func")
a.assert_match("suffix match gets icon", result.kind, " " .. formatter.ICON .. " ")

result = format_entry(make_entry("concatenation"), "cat")
a.assert_match("substring match gets icon", result.kind, " " .. formatter.ICON .. " ")

result = format_entry(make_entry("test"), "test")
a.assert_match("preserves kind prefix", result.kind, "Text")

local vim_item = {}
result = formatter.format(make_entry("test"), vim_item)
a.assert_true("works without initial kind", result.kind ~= nil)

result = format_entry(make_entry("on", "handler"), "handler")
a.assert_match("insertText match gets icon", result.kind, " " .. formatter.ICON .. " ")

result = format_entry(make_entry("handler", "on"), "handler")
a.assert_match("label match gets icon", result.kind, " " .. formatter.ICON .. " ")

result = format_entry(make_entry("alpha", "beta"), "gamma")
a.assert_match("no match padding", result.kind, "   ")

local long = string.rep("x", 500)
result = format_entry(make_entry(long), long)
a.assert_match("long exact match", result.kind, " " .. formatter.ICON .. " ")

result = format_entry(make_entry("other"), long)
a.assert_match("long no match", result.kind, "   ")

result = format_entry(make_entry("café"), "café")
a.assert_match("unicode match", result.kind, " " .. formatter.ICON .. " ")

state.prediction = "test[1]"
result = format_entry(make_entry("test[1]"), "test[1]")
a.assert_match("special char match", result.kind, " " .. formatter.ICON .. " ")

state.prediction = "myFunc"
vim_item = { kind = "Function" }
result = formatter.format(make_entry("myFunc"), vim_item)
a.assert_match("preserves Function kind", result.kind, "Function")
a.assert_match("Function with icon", result.kind, " " .. formatter.ICON .. " ")

vim_item = { kind = "Method" }
result = formatter.format(make_entry("myMeth"), vim_item)
a.assert_match("preserves Method kind", result.kind, "Method")

state.prediction = "test"
local entry_empty_label = {
  completion_item = {
    label = "",
    insertText = "test"
  }
}
result = formatter.format(entry_empty_label, { kind = "" })
a.assert_match("empty label, matching insertText", result.kind, " " .. formatter.ICON .. " ")

state.prediction = "test"
local entry_nil_label = {
  completion_item = {
    label = nil,
    insertText = "test"
  }
}
result = formatter.format(entry_nil_label, { kind = "" })
a.assert_match("nil label, matching insertText", result.kind, " " .. formatter.ICON .. " ")

state.prediction = "test"
local entry_both_nil = {
  completion_item = {
    label = nil,
    insertText = nil
  }
}
result = formatter.format(entry_both_nil, { kind = "" })
a.assert_match("both nil, no match", result.kind, "   ")

a.report("Formatter Tests")
a.exit_if_failed()
