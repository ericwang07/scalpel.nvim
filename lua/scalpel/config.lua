local M = {}

M.defaults = {
	-- Path to the Rust binary. If nil, we'll try to find it in the plugin directory.
	binary_path = nil,
	-- Port the server should listen on.
	port = 3000,
  -- Default keymaps. Set to false to disable.
  -- Example: { complete = "<C-k>" }
  keymaps = {
    complete = nil,
  },
}

M.options = {}

function M.setup(opts)
	M.options = vim.tbl_deep_extend("force", M.defaults, opts or {})
    M.options.server_url = "http://127.0.0.1:" .. M.options.port
end

return M
