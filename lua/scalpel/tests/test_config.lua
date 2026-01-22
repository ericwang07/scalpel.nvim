package.path = package.path .. ";./lua/?.lua"

local config = require("scalpel.config")
local a = require("scalpel.tests.helpers")

print("=== Config Tests ===")

config.setup()
a.assert_eq("default port", config.options.port, 3000)
a.assert_eq("default binary_path nil", config.options.binary_path, nil)
a.assert_eq("default keymaps complete nil", config.options.keymaps.complete, nil)
a.assert_eq("default server_url", config.options.server_url, "http://127.0.0.1:3000")

config.setup({ port = 8080 })
a.assert_eq("custom port", config.options.port, 8080)
a.assert_eq("custom server_url", config.options.server_url, "http://127.0.0.1:8080")

config.setup({ keymaps = { complete = "<C-k>" } })
a.assert_eq("custom keymap", config.options.keymaps.complete, "<C-k>")

config.setup(nil)
a.assert_eq("nil opts port", config.options.port, 3000)
a.assert_eq("nil opts keymaps", config.options.keymaps.complete, nil)

config.setup({})
a.assert_eq("empty opts port", config.options.port, 3000)

config.setup({ keymaps = { complete = "<C-a>", other = "test" } })
a.assert_eq("deep merge keymap", config.options.keymaps.complete, "<C-a>")
a.assert_eq("deep merge other field", config.options.keymaps.other, "test")

config.setup({ port = 99999 })
a.assert_eq("out of range port stored", config.options.port, 99999)

config.setup({ port = "4000" })
a.assert_eq("string port stored", config.options.port, "4000")

config.setup({ port = 5000 })
a.assert_eq("first setup", config.options.port, 5000)
config.setup({ port = 6000 })
a.assert_eq("second setup override", config.options.port, 6000)

config.setup({ port = 1234 })
a.assert_eq("server_url recomputed", config.options.server_url, "http://127.0.0.1:1234")

a.report("Config Tests")
a.exit_if_failed()
