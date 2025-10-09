local health = vim.health

local M = {}

local function get_exe_info(name, version_arg)
	if vim.fn.executable(name) == 1 then
		local path = vim.fn.exepath(name)
		local out = vim.trim(vim.fn.system({ name, version_arg or "--version" }))
		local version = vim.version.parse(out)
		return { path = path, version = version, out = out }
	end
end

local function report_health_fail(info, error)
	if error then
		health.error(info)
	else
		health.warn(info)
	end
end

local function check_haxelib(lib, required)
	required = required or false
	-- if vim.fn.executable("haxelib") == 0 then
	-- 	report_health_fail("`haxelib` command not found in PATH", false)
	-- 	return
	-- end
	local ok = vim.fn.system({ "haxelib", "path", lib })
	if vim.v.shell_error ~= 0 or ok:match("Library %S+ is not installed") then
		-- health.error(("Haxelib '%s' is not installed"):format(lib))
		report_health_fail(("Haxelib '%s' is not installed"):format(lib), required)
	else
		local version = ok:match("(%d+[%d%.]*)")
		if version then
			health.ok(("Haxelib '%s' is installed (version %s)"):format(lib, version))
		else
			health.ok(("Haxelib '%s' is installed"):format(lib))
		end
	end
end

local function check_plugin(plugin, required)
	required = required or false
	local plugin_available = pcall(require, plugin)
	if plugin_available then
		health.ok(plugin .. " is available")
	else
		if required then
			health.error(plugin .. " is not available")
		else
			health.warn(plugin .. " is not available")
		end
	end
	return plugin_available
end

function M.check()
	if vim.fn.has("nvim-0.11.4") == 1 then
		health.ok("nvim >= 0.11.4")
	else
		health.error("nvim < 0.11.4")
	end

	local haxe_ver_min = "4.3.7"
	local haxe_ver = get_exe_info("haxe")
	if not haxe_ver then
		health.error("haxe not found in $PATH")
		return
	end
	local haxe_required = vim.version.parse(haxe_ver_min)
	local haxe_installed = vim.version.parse(haxe_ver.out)
	local cmp = vim.version.cmp(haxe_installed, haxe_required)
	local msg = ("haxe: %s, version: %s"):format(haxe_ver.path, haxe_ver.out)
	if cmp >= 0 then
		health.ok(msg .. " (meets minimum " .. haxe_ver_min .. ")")
	else
		health.error(msg .. " (requires >= " .. haxe_ver_min .. ")")
	end

	local hashlink_ver = get_exe_info("hl")
	if not hashlink_ver then
		health.warn("hashlink not found in $PATH")
	else
		health.ok(("hashlink: %s, version: %s"):format(hashlink_ver.path, hashlink_ver.out))
	end

	check_plugin("dap", true)
	check_plugin("dapui", false)

	check_plugin("nvim-treesitter", true)
	if not require("nvim-treesitter.parsers").haxe then
		health.error("tree-sitter-haxe is not available")
	end
	if not require("nvim-treesitter.parsers").hxml then
		health.error("tree-sitter-hxml is not available")
	end

	check_haxelib("hxcpp-debug-server", false)

	--TODO: check if bundled adapters exist
	-- local plugin_root = vim.fs.dirname(vim.fs.dirname(vim.fs.dirname(debug.getinfo(1, "S").source:sub(2))))
	--check_file_exists(plugin_root.."")
end

return M
