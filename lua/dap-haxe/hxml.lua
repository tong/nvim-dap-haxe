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

-- parse HXML and return the first target flag and output
local function parse_hxml(path)
	local content = read_file(path)
	if not content then
		return
	end
	local parser = ts.get_string_parser(content, "hxml")
	local tree = parser:parse()[1]
	local root = tree:root()
	for node in root:iter_children() do
		if node:type() == "target" then
			local text = ts.get_node_text(node, content)
			local flag, file = text:match("^(%S+)%s*(.*)")
			return flag, file
		end
	end
end

-- returns a DAP config table from a .hxml file
function M.config_from_hxml(hxml_path)
	local flag, output = parse_hxml(hxml_path)
	if not flag then
		vim.notify("No target found in " .. hxml_path, vim.log.levels.ERROR)
		return nil
	end
	local abs_output = output ~= "" and vim.fn.fnamemodify(output, ":p") or nil
	if flag == "--hl" then
		return {
			name = "Run " .. (output or "<unknown>"),
			type = "hashlink",
			request = "launch",
			cwd = "${workspaceFolder}",
			program = abs_output,
			stopOnEntry = false,
		}
	elseif flag == "--js" then
		return {
			name = "Run " .. (output or "<unknown>"),
			type = "pwa-node",
			request = "launch",
			cwd = "${workspaceFolder}",
			program = abs_output,
			stopOnEntry = true,
			sourceMaps = true,
			sourceMapPathOverrides = { ["file:////"] = "/" },
		}
	elseif flag == "--interp" then
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
		vim.notify("Unsupported target " .. flag, vim.log.levels.WARN)
		return nil
	end
end

return M
