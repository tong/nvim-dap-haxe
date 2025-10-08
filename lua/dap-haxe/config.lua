-- ISSUE:
-- local plugin_root = vim.fn.stdpath("data") .. "/lazy/nvim-dap-haxe"
local plugin_root = vim.fs.dirname(vim.fs.dirname(vim.fs.dirname(debug.getinfo(1, "S").source:sub(2))))

--TODO:

---@class DapHaxeHaxeConfig
---@field bin string
---@field env table<string, string>

---@class DapHaxeAdapterConfig
---@field path string
---@field args_templates? table<string, function>

---@class DapHaxeAdaptersConfig
---@field haxe DapHaxeAdapterConfig
---@field hashlink DapHaxeAdapterConfig
---@field hxcpp DapHaxeAdapterConfig

---@class DapHaxeJavascriptConfig
---@field program string

---@class DapHaxeConfig
---@field haxe DapHaxeHaxeConfig
---@field adapters DapHaxeAdaptersConfig
---@field javascript DapHaxeJavascriptConfig

---@type DapHaxeConfig
--
local M = {
	haxe = {
		bin = "haxe",
		env = {},
	},
	adapters = {
		haxe = {
			path = plugin_root .. "/adapter/eval.js",
			args_templates = {
				call = function()
					local dap_haxe = require("dap-haxe")
					local mod = dap_haxe.get_module_path()
					local fun = dap_haxe.get_current_function() or "main"
					return { "--macro", string.format("'%s.%s()'", mod, fun) }
				end,
				run = function()
					local dap_haxe = require("dap-haxe")
					local mod = dap_haxe.get_module_path()
					return { "--run", mod }
				end,
			},
		},
		hashlink = {
			path = plugin_root .. "/adapter/hl.js",
		},
		hxcpp = {
			path = plugin_root .. "/adapter/hxcpp.js",
		},
	},
	javascript = {
		program = "",
	},
}

function M.setup(opts)
	vim.tbl_deep_extend("force", {}, M, opts or {})
end

return M
