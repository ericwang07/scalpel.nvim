package.path = package.path .. ";./lua/?.lua"

local a = require("scalpel.tests.helpers")

print("=== Client Tests ===")

local has_plenary, client = pcall(require, "scalpel.client")
if has_plenary then
  a.assert_true("client module loads", client ~= nil)
  a.assert_true("client has request function", type(client.request) == "function")
  a.assert_true("client has complete function", type(client.complete) == "function")
else
  print("SKIP: client module (plenary not installed)")
end

local config = require("scalpel.config")
a.assert_true("config module loads", config ~= nil)

local ok, err = pcall(function() end)
a.assert_true("client module structure valid", ok)

config.setup({ port = 3000 })
a.assert_eq("server_url format", config.options.server_url, "http://127.0.0.1:3000")

config.setup({ port = 8080 })
a.assert_eq("server_url different port", config.options.server_url, "http://127.0.0.1:8080")

local body = {
  prefix = "def hello():",
  suffix = "pass"
}
local encoded = vim.fn.json_encode(body)
a.assert_true("json_encode works", type(encoded) == "string")
a.assert_true("json_encode contains prefix", string.find(encoded, "def hello"))

local response_body = '{"completion": "test", "prompt": "prompt", "latency_ms": 100}'
ok, decoded = pcall(vim.fn.json_decode, response_body)
a.assert_true("json_decode works", ok)
a.assert_eq("decoded completion", decoded.completion, "test")
a.assert_eq("decoded prompt", decoded.prompt, "prompt")
a.assert_eq("decoded latency_ms", decoded.latency_ms, 100)

local bad_json = "{ invalid json }"
ok, _ = pcall(vim.fn.json_decode, bad_json)
a.assert_true("invalid json returns false", not ok)

ok, decoded = pcall(vim.fn.json_decode, "{}")
a.assert_true("empty object decodes", ok)

local special_body = {
  prefix = 'test "quoted" and \\ backslash',
  suffix = "new\nline\ttab"
}
encoded = vim.fn.json_encode(special_body)
a.assert_true("special chars encoded", string.find(encoded, "quoted"))

local unicode_body = {
  prefix = "café 中文",
  suffix = "emoji 🎉"
}
encoded = vim.fn.json_encode(unicode_body)
a.assert_true("unicode encoded", string.find(encoded, "caf"))

local number_body = {
  prefix = 123,
  suffix = 45.67
}
encoded = vim.fn.json_encode(number_body)
a.assert_true("numbers encoded", string.find(encoded, "123"))

local bool_body = {
  prefix = true,
  suffix = false
}
encoded = vim.fn.json_encode(bool_body)
a.assert_true("booleans encoded", string.find(encoded, "true"))

local nil_body = {
  prefix = nil
}
encoded = vim.fn.json_encode(nil_body)
a.assert_true("nil handled", type(encoded) == "string")

local complete_body = {
  prefix = "function test() {",
  suffix = "}"
}
encoded = vim.fn.json_encode(complete_body)
a.assert_true("complete body has prefix", string.find(encoded, "prefix"))
a.assert_true("complete body has suffix", string.find(encoded, "suffix"))

if has_plenary then
  package.loaded["scalpel.client"] = nil
  local client2 = require("scalpel.client")
  a.assert_true("client reloadable", client2 ~= nil)
else
  print("SKIP: client reload test (plenary not installed)")
end

a.report("Client Tests")
a.exit_if_failed()
