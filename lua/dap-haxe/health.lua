local health = vim.health

local M = {}

local function check_exe(name, version_arg)
	if vim.fn.executable(name) == 1 then
		local path = vim.fn.exepath(name)
		local out = vim.trim(vim.fn.system({ name, version_arg or "--version" }))
		local version = vim.version.parse(out)
		return { path = path, version = version, out = out }
	end
end

local function isi_plugin_available(plugin, required)
	required = required or false
	local is_plugin_available = pcall(require, plugin)
	if is_plugin_available then
		health.ok(plugin .. " is available")
	else
		if required then
			health.error(plugin .. " is not available")
		else
			health.warn(plugin .. " is not available")
		end
	end
	return is_plugin_available
end

function M.check()
	if vim.fn.has("nvim-0.11.4") == 1 then
		health.ok("nvim >= 0.11.4")
	else
		health.error("nvim < 0.11.4")
	end

	local haxe_ver = check_exe("haxe")
	if not haxe_ver then
		health.error("Haxe not found in $PATH")
		return
	end
	local haxe_required = vim.version.parse("4.3.7")
	local haxe_installed = vim.version.parse(haxe_ver.out)
	local cmp = vim.version.cmp(haxe_installed, haxe_required)
	local msg = ("haxe: %s, version: %s"):format(haxe_ver.path, haxe_ver.out)
	if cmp >= 0 then
		health.ok(msg .. " (meets minimum 4.3.7)")
	else
		health.error(msg .. " (requires >= 4.3.7)")
	end

	local hashlink_ver = check_exe("hl")
	if not hashlink_ver then
		health.warn("hashlink not found in $PATH")
	else
		health.ok(("hashlink: %s, version: %s"):format(hashlink_ver.path, hashlink_ver.out))
	end

	M.is_plugin_available("dap", true)
	M.is_plugin_available("dapui", false)

	M.is_plugin_available("nvim-treesitter", true)
	if not require("nvim-treesitter.parsers").haxe then
		health.error("tree-sitter-haxe is not available")
	end
	if not require("nvim-treesitter.parsers").hxml then
		health.error("tree-sitter-hxml is not available")
	end
end

return M
