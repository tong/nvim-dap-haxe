local M = {}

function M.setup(opts)
	-- vim.notify(vim.inspect(opts))

	local dap = require("dap")

	dap.adapters.haxe_eval = {
		type = "executable",
		command = "node",
		args = { "/home/tong/src/vshaxe/eval-debugger/bin/index.js", "--stdio" },
	}

	dap.adapters.hashlink = {
		type = "executable",
		command = "node",
		args = { "/home/tong/src/hashlink-debugger/adapter.js" },
	}

	dap.configurations.haxe = {
		{
			name = "Debug haxe->eval",
			type = "haxe_eval",
			request = "launch",
			cwd = "${workspaceFolder}",
			stopOnEntry = false,
			args = { "--macro", "'App.test()'" },
			haxeExecutable = {
				executable = "haxe",
				env = {},
			},
		},
		{
			name = "Debug haxe->hashlink",
			type = "hashlink",
			request = "launch",
			cwd = "${workspaceFolder}",
			classPaths = "${workspaceFolder}",
			stopOnEntry = false,
			program = function()
				local cwd = vim.fn.getcwd()
				local files = vim.fn.globpath(cwd, "**/*.hl", false, true)
				if #files == 0 then
					error("No .hl file found in workspace!")
				end
				-- Optionally, prompt if more than one found:
				if #files > 1 then
					return vim.fn.input("Select .hl file: ", files[1], "file")
				end
				return files[1]
			end,
		},
		{
			name = "Debug haxe->javascript",
			type = "pwa-node",
			request = "launch",
			cwd = "${workspaceFolder}",
			stopOnEntry = true,
			program = function()
				local cwd = vim.fn.getcwd()
				local files = vim.fn.globpath(cwd, "**/*.js", false, true)
				if #files == 0 then
					error("No .js file found in workspace!")
				end
				if #files > 1 then
					return vim.fn.input("Select .js file to launch: ", files[1], "file")
				end
				return files[1]
			end,
			sourceMaps = true,
			-- This override helps map the absolute paths in the Haxe-generated
			-- sourcemap back to the files on your local system.
			sourceMapPathOverrides = {
				["file:////"] = "/",
			},
		},
	}
end

return M
