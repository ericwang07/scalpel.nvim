local config = require("scalpel.config")
local M = {}
M.job_id = nil

-- Helper to find the binary path
local function get_binary_path()
	if config.options.binary_path then
		return config.options.binary_path
	end
	-- Default: Look in server/target/release/ relative to the plugin root
	-- This assumes the user has built the binary.
	-- Relative calculation of the root
	local plugin_root = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":h:h:h")
	local bin_path = plugin_root .. "/server/target/release/scalpel"

	if vim.fn.executable(bin_path) == 1 then
		return bin_path
	end

	return nil
end

function M.start()
	-- Check if already running
	if M.job_id then
		vim.notify("Scalpel server is already running (PID: " .. M.job_id .. ")", vim.log.levels.INFO)
		return
	end
	-- Get binary path
	local bin = get_binary_path()
	if not bin then
		vim.notify("Scalpel server binary not found. Please build it or configure 'binary_path'.", vim.log.levels.ERROR)
		return
	end
	local cmd = { bin }
	
	local job_opts = {
		env = {
			SCALPEL_PORT = tostring(config.options.port),
			-- Inherit other env vars if needed, or let vim.fn.jobstart handle it (it inherits by default)
		},
		detach = false,
		on_stdout = function(_, data)
			if data then
				-- Log stdout if needed
				for _, line in ipairs(data) do
					if line ~= "" then
						print("[Scalpel] " .. line)
					end
				end
			end
		end,
		on_stderr = function(_, data)
			if data then 
				-- Log stdout if needed
				for _, line in ipairs(data) do
					if line ~= "" then
						print("[Scalpel] " .. line)
					end
				end
			end
		end,
		on_exit = function(_, code)
			M.job_id = nil
			if M.is_restarting then
				M.is_restarting = false
				vim.schedule(function() -- ensure the main thread is used
					M.start()
				end)
				return
			elseif code ~= 0 and code ~= 143 then -- 143 is SIGTERM, ignore it
				vim.notify("Scalpel server exited with code " .. code, vim.log.levels.WARN)
			end
		end,
	}
	M.job_id = vim.fn.jobstart(cmd, job_opts)
	if M.job_id <= 0 then
		vim.notify("Failed to start Scalpel server", vim.log.levels.ERROR)
		M.job_id = nil
	else
		vim.notify("Scalpel server started (PID: " .. M.job_id .. ")", vim.log.levels.INFO)
	end
end

function M.stop()
	if M.job_id then
		vim.fn.jobstop(M.job_id)
		M.job_id = nil
		vim.notify("Scalpel server stopped", vim.log.levels.INFO)
	end
end

function M.restart()
	if M.job_id then
		M.is_restarting = true
		M.stop()
	else
		M.start()
	end
end

return M
