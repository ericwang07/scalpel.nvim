package.path = package.path .. ";./lua/?.lua"

package.loaded["scalpel.state"] = nil
_G.ScalpelState = { prediction = nil }

local state = require("scalpel.state")
local matcher = require("scalpel.matcher")
local comparator = require("scalpel.comparator")
local a = require("scalpel.tests.helpers")

print("=== Comparator Tests ===")

local function make_entry(label, insertText)
  insertText = insertText or label
  return {
    completion_item = {
      label = label,
      insertText = insertText,
    }
  }
end

state.prediction = nil
a.assert_nil("nil prediction defers (e1)", comparator(make_entry("test"), make_entry("test2")))

state.prediction = ""
a.assert_nil("empty prediction defers (e1)", comparator(make_entry("test"), make_entry("test2")))

state.prediction = "function"
a.assert_true("entry1 higher score", comparator(
  make_entry("function"),
  make_entry("func")
))

a.assert_eq("entry2 higher score", comparator(
  make_entry("func"),
  make_entry("function")
), false)

state.prediction = "concat"
a.assert_eq("only entry2 matches", comparator(
  make_entry("different"),
  make_entry("concat")
), false)

local entry_nil_label = {
  completion_item = {
    label = nil,
    insertText = "function"
  }
}
state.prediction = "function"
a.assert_eq("nil label defers", comparator(entry_nil_label, make_entry("function")), nil)

state.prediction = "test"
local both_nil_label = {
  completion_item = {
    label = nil,
    insertText = nil
  }
}
a.assert_nil("both nil label", comparator(both_nil_label, both_nil_label))

state.prediction = "test"
local entry_empty_label = {
  completion_item = {
    label = "",
    insertText = "test"
  }
}
a.assert_true("empty label, matching insertText", comparator(entry_empty_label, make_entry("other")))

state.prediction = "handler"
local e1 = make_entry("handler", "different")
local e2 = make_entry("different", "handler")
a.assert_nil("both have one match each", comparator(e1, e2))

a.report("Comparator Tests")
a.exit_if_failed()
