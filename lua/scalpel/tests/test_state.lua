package.path = package.path .. ";./lua/?.lua"

local a = require("scalpel.tests.helpers")

print("=== State Tests ===")

local original_prediction = _G.ScalpelState and _G.ScalpelState.prediction

package.loaded["scalpel.state"] = nil
_G.ScalpelState = nil

local state1 = require("scalpel.state")
a.assert_true("state creates _G.ScalpelState", _G.ScalpelState ~= nil)
a.assert_eq("initial prediction nil", state1.prediction, nil)

state1.prediction = "test prediction"
a.assert_eq("prediction set", state1.prediction, "test prediction")

package.loaded["scalpel.state"] = nil
local state2 = require("scalpel.state")
a.assert_eq("singleton returns same prediction", state2.prediction, "test prediction")

state2.prediction = "modified"
a.assert_eq("modification visible via state1", state1.prediction, "modified")

_G.ScalpelState.prediction = "direct"
a.assert_eq("direct _G modification", state1.prediction, "direct")

state1.prediction = "first"
state1.prediction = "second"
state1.prediction = "third"
a.assert_eq("multiple updates", state1.prediction, "third")

state1.prediction = nil
a.assert_eq("set to nil", state1.prediction, nil)

state1.prediction = ""
a.assert_eq("set to empty string", state1.prediction, "")

state1.prediction = 123
a.assert_eq("number prediction", state1.prediction, 123)

state1.prediction = true
a.assert_eq("boolean prediction", state1.prediction, true)

state1.prediction = { a = 1, b = 2 }
a.assert_eq("table prediction", state1.prediction.a, 1)

local long_str = string.rep("x", 10000)
state1.prediction = long_str
a.assert_eq("long string", state1.prediction, long_str)

if original_prediction ~= nil then
  _G.ScalpelState.prediction = original_prediction
end

a.report("State Tests")
a.exit_if_failed()
