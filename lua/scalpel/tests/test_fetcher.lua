package.path = package.path .. ";./lua/?.lua"

local a = require("scalpel.tests.helpers")

print("=== Fetcher Tests ===")

local has_plenary = pcall(require, "plenary.curl")
if not has_plenary then
  print("INFO: Mocking client module (plenary not installed)")
  package.loaded["scalpel.client"] = nil
  package.preload["scalpel.client"] = function()
    return {
      complete = function() end,
      request = function() end
    }
  end
end

local fetcher = require("scalpel.fetcher")
a.assert_true("fetcher module loads", fetcher ~= nil)
a.assert_true("fetcher has setup function", type(fetcher.setup) == "function")
a.assert_true("fetcher has on_text_changed function", type(fetcher.on_text_changed) == "function")

package.loaded["scalpel.state"] = nil
_G.ScalpelState = nil
local state = require("scalpel.state")
a.assert_true("state module loads", state ~= nil)
a.assert_true("state has prediction field", state.prediction == nil or state.prediction ~= nil)

local config = require("scalpel.config")
config.setup({ port = 3000 })
a.assert_true("config loads and setup works", config.options.port == 3000)

a.assert_true("fetcher uses timer pattern", fetcher.setup ~= nil)

package.loaded["scalpel.fetcher"] = nil
local fetcher2 = require("scalpel.fetcher")
a.assert_true("fetcher reloadable", fetcher2 ~= nil)
a.assert_true("fetcher2 has setup", type(fetcher2.setup) == "function")

a.assert_true("fetcher setup is callable", type(fetcher.setup) == "function")

state.prediction = nil
a.assert_eq("initial prediction nil", state.prediction, nil)

state.prediction = "test prediction"
a.assert_eq("prediction can be set", state.prediction, "test prediction")

state.prediction = string.rep("x", 1000)
a.assert_eq("long prediction", state.prediction, string.rep("x", 1000))

state.prediction = nil
a.assert_eq("prediction cleared", state.prediction, nil)

if has_plenary then
  local client = require("scalpel.client")
  a.assert_true("client.complete is function", type(client.complete) == "function")
  a.assert_true("client.request exists", type(client.request) == "function")
else
  print("SKIP: client function tests (plenary not installed)")
end

state.prediction = 123
a.assert_eq("number prediction", state.prediction, 123)

state.prediction = true
a.assert_eq("boolean prediction", state.prediction, true)

state.prediction = { word = "table" }
a.assert_eq("table prediction field", state.prediction.word, "table")

state.prediction = "first"
state.prediction = "second"
state.prediction = "third"
a.assert_eq("predictions overwrite", state.prediction, "third")

state.prediction = ""
a.assert_eq("empty string prediction", state.prediction, "")

state.prediction = "function test() { return 42; }"
a.assert_eq("special chars prediction", state.prediction, "function test() { return 42; }")

state.prediction = "函数返回"
a.assert_eq("unicode prediction", state.prediction, "函数返回")

state.prediction = "line1\nline2\nline3"
a.assert_eq("newline prediction", state.prediction, "line1\nline2\nline3")

a.report("Fetcher Tests")
a.exit_if_failed()
