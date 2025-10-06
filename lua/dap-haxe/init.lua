local M = {}

-- local plugin_root = vim.fn.stdpath("data") .. "/lazy/nvim-dap-haxe"
local plugin_root = vim.fs.dirname(vim.fs.dirname(vim.fs.dirname(debug.getinfo(1, "S").source:sub(2))))

M.defaults = {
	haxe = {
		executable = "haxe",
		env = {},
	},
	adapters = {
		eval = {
			type = "haxe_eval",
			cwd = "${workspaceFolder}",
			stopOnEntry = false,
			args_templates = {
				function_call = function()
					local mod = M.get_module_path()
					local fn = M.get_current_function() or "main"
					return { "--macro", string.format("'%s.%s()'", mod, fn) }
				end,
				run_file = function()
					local mod = M.get_module_path()
					return { "--run", mod }
				end,
			},
		},
		hashlink = {
			type = "hashlink",
			cwd = "${workspaceFolder}",
			stopOnEntry = false,
		},
	},
	javascript = {
		cwd = "${workspaceFolder}",
		program = nil,
	},
}

function M.get_module_path()
	local rel = vim.fn.fnamemodify(vim.fn.expand("%:r"), ":.")
	rel = rel:gsub("/", "."):gsub("\\", ".")
	rel = rel:gsub("^src%.", "")
	return rel
end

function M.get_current_function()
	local node = vim.treesitter.get_node()
	while node do
		if node:type() == "function_declaration" then
			for child in node:iter_children() do
				if child:type() == "identifier" then
					return vim.treesitter.get_node_text(child, 0)
				end
			end
		end
		node = node:parent()
	end
	return nil
end

function M.setup(opts)
	M.config = vim.tbl_deep_extend("force", M.defaults, opts or {})

	local dap = require("dap")
	local hxml = require("dap-haxe.hxml")

	dap.adapters.haxe_eval = {
		type = "executable",
		command = "node",
		args = { plugin_root .. "/adapter/eval.js", "--stdio" },
	}

	dap.adapters.hashlink = {
		type = "executable",
		command = "node",
		args = { plugin_root .. "/adapter/hl.js" },
	}

	local function get_hxml_cfg(bufnr)
		bufnr = bufnr or 0
		local path = vim.api.nvim_buf_get_name(bufnr)
		if path == "" then
			return nil
		end
		local cfg = hxml.config_from_hxml(path)
		if not cfg then
			vim.notify("Failed to parse HXML: " .. path, vim.log.levels.ERROR)
			return nil
		end
		if cfg.type == "hashlink" and not cfg.classPaths then
			cfg.classPaths = { vim.fn.fnamemodify(vim.fn.getcwd(), ":p") }
		end
		return cfg
	end

	dap.configurations.hxml = {
		{
			name = "hxml:current",
			request = "launch",
			cwd = "${workspaceFolder}",
			stopOnEntry = false,
			type = function()
				local cfg = get_hxml_cfg()
				return cfg and cfg.type or "haxe_eval"
			end,
			program = function()
				local cfg = get_hxml_cfg()
				return cfg and cfg.program or "."
			end,
			args = function()
				local cfg = get_hxml_cfg()
				return cfg and cfg.args or {}
			end,
			classPaths = function()
				local cfg = get_hxml_cfg()
				return cfg and cfg.classPaths
			end,
		},
	}

	dap.configurations.haxe = dap.configurations.haxe or {}

	table.insert(dap.configurations.haxe, {
		name = "haxe:hxml",
		request = "launch",
		cwd = "${workspaceFolder}",
		type = function()
			local path = vim.fn.input("Path to .hxml: ", "build.hxml", "file")
			local cfg = hxml.config_from_hxml(path)
			if not cfg then
				vim.notify("Failed to parse HXML: " .. path, vim.log.levels.ERROR)
				return "haxe_eval"
			end
			return cfg.type
		end,
		program = function()
			local path = vim.fn.input("Path to .hxml: ", "build.hxml", "file")
			local cfg = hxml.config_from_hxml(path)
			if not cfg then
				return nil
			end
			return cfg.program or "."
		end,
		args = function()
			local path = vim.fn.input("Path to .hxml: ", "build.hxml", "file")
			local cfg = hxml.config_from_hxml(path)
			if not cfg then
				return {}
			end
			return cfg.args or {}
		end,
		stopOnEntry = false,
		-- For hashlink, add classPaths dynamically if missing
		classPaths = function()
			local path = vim.fn.input("Path to .hxml: ", "build.hxml", "file")
			local cfg = hxml.config_from_hxml(path)
			if not cfg then
				return {}
			end
			if cfg.type == "hashlink" then
				return { vim.fn.fnamemodify(vim.fn.getcwd(), ":p") }
			end
			return nil
		end,
	})

	-- eval:function / eval:run
	for name, template in pairs(M.config.adapters.eval.args_templates or {}) do
		table.insert(dap.configurations.haxe, {
			name = "eval:" .. name,
			type = M.config.adapters.eval.type,
			request = "launch",
			cwd = M.config.adapters.eval.cwd,
			-- program = ".", -- dummy file for eval adapter
			args = template,
			stopOnEntry = M.config.adapters.eval.stopOnEntry,
			haxeExecutable = M.config.haxe,
		})
	end

	-- hashlink
	table.insert(dap.configurations.haxe, {
		name = "hashlink",
		type = "hashlink",
		request = "launch",
		cwd = "${workspaceFolder}",
		classPaths = { "${workspaceFolder}" },
		stopOnEntry = false,
		program = function()
			local cwd = vim.fn.getcwd()
			local files = vim.fn.globpath(cwd, "**/*.hl", false, true)
			if #files == 0 then
				vim.notify("No .hl file found in workspace!", vim.log.levels.WARN)
				return nil
			end
			if #files > 1 then
				return vim.fn.input("Select .hl file: ", files[1], "file")
			end
			return files[1]
		end,
	})

	-- javascript
	table.insert(dap.configurations.haxe, {
		name = "javascript",
		type = "pwa-node",
		request = "launch",
		cwd = M.config.javascript.cwd,
		stopOnEntry = true,
		program = function()
			if M.config.javascript.program and M.config.javascript.program ~= "" then
				local js_path = vim.fn.expand(M.config.javascript.program)
				local js_stat = vim.loop.fs_stat(js_path)
				local map_stat = vim.loop.fs_stat(js_path .. ".map")
				if js_stat and js_stat.type == "file" and map_stat and map_stat.type == "file" then
					return js_path
				else
					vim.notify(
						"Configured javascript.program ('"
							.. js_path
							.. "') not found or is missing a .map file. Falling back to workspace search.",
						vim.log.levels.WARN
					)
				end
			end
			local cwd = vim.fn.getcwd()
			local all_js_files = vim.fn.globpath(cwd, "**/*.js", false, true)
			if type(all_js_files) == "string" then
				if all_js_files == "" then
					all_js_files = {}
				else
					all_js_files = vim.split(all_js_files, "\n")
				end
			end
			local valid_files = {}
			for _, file in ipairs(all_js_files) do
				if file ~= "" then
					local map_stat = vim.loop.fs_stat(file .. ".map")
					if map_stat and map_stat.type == "file" then
						table.insert(valid_files, file)
					end
				end
			end
			if #valid_files == 0 then
				vim.notify("No .js file with a corresponding .js.map file found in workspace!", vim.log.levels.ERROR)
				return nil
			end
			if #valid_files > 1 then
				return vim.fn.input("Select .js file to launch: ", valid_files[1], "file")
			end
			return valid_files[1]
		end,
		sourceMaps = true,
		sourceMapPathOverrides = {
			["file:////"] = "/",
		},
	})
end

return M
