local ts = vim.treesitter

local M = {}

-- read the entire HXML file
local function read_file(path)
	local f = io.open(path, "r")
	if not f then
		return nil
	end
	local content = f:read("*a")
	f:close()
	return content
end

-- parse HXML and return the flags and outputs
local function parse_hxml(path)
	local content = read_file(path)
	if not content then
		return nil
	end
	local parser = ts.get_string_parser(content, "hxml")
	local tree = parser:parse()[1]
	local root = tree:root()
	local result = { libraries = {} }
	for node in root:iter_children() do
		local text = ts.get_node_text(node, content)
		local key, val = text:match("^(%S+)%s*(.*)")
		if key == "--main" then
			result.main = val
		elseif key == "--debug" then
			result.debug = true
		elseif key == "--library" or key == "-L" then
			table.insert(result.libraries, val)
		elseif node:type() == "target" then
			result.target_flag = key
			result.target_output = val
		end
	end
	return result
end

-- returns a DAP config table from a .hxml file
function M.config_from_hxml(hxml_path)
	local hxml = parse_hxml(hxml_path)
	if not hxml or not hxml.target_flag then
		vim.notify("No target found in " .. hxml_path, vim.log.levels.ERROR)
		return nil
	end

	local abs_output = nil
	if hxml.target_output and hxml.target_output ~= "" then
		abs_output = vim.fn.fnamemodify(hxml.target_output, ":p")
	end

	if hxml.target_flag == "--hl" then
		return {
			name = "Run " .. (hxml.target_output or "<unknown>"),
			type = "hashlink",
			request = "launch",
			cwd = "${workspaceFolder}",
			program = abs_output,
			stopOnEntry = false,
		}
	elseif hxml.target_flag == "--js" then
		return {
			name = "Run " .. (hxml.target_output or "<unknown>"),
			type = "pwa-node",
			request = "launch",
			cwd = "${workspaceFolder}",
			program = abs_output,
			stopOnEntry = true,
			sourceMaps = true,
			sourceMapPathOverrides = { ["file:////"] = "/" },
		}
	elseif hxml.target_flag == "--cpp" then
		if not hxml.main then
			vim.notify("No --main found in " .. hxml_path .. " for --cpp target", vim.log.levels.ERROR)
			return nil
		end

		if not hxml.debug then
			vim.notify("--debug flag is missing in " .. hxml_path, vim.log.levels.ERROR)
			return nil
		end

		local has_debug_lib = false
		for _, lib in ipairs(hxml.libraries) do
			if lib == "hxcpp-debug-server" then
				has_debug_lib = true
				break
			end
		end
		if not has_debug_lib then
			vim.notify("--library hxcpp-debug-server is missing in " .. hxml_path, vim.log.levels.ERROR)
			return nil
		end

		local program_name = hxml.main
		if hxml.debug then
			program_name = program_name .. "-debug"
		end
		local program_path = abs_output .. "/" .. program_name
		return {
			name = "Run " .. program_name,
			type = "hxcpp",
			program = program_path,
			request = "launch",
			cwd = "${workspaceFolder}",
			stopOnEntry = true,
		}
	elseif hxml.target_flag == "--interp" then
		return {
			name = "Run eval",
			type = "haxe_eval",
			request = "launch",
			cwd = "${workspaceFolder}",
			args = { "--interp" },
			stopOnEntry = false,
			haxeExecutable = vim.fn.exepath("haxe"),
		}
	else
		vim.notify("Unsupported target " .. hxml.target_flag, vim.log.levels.WARN)
		return nil
	end
end

return M

