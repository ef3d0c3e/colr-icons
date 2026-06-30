local icons = require("colr-icons.icons")
local M = {}


local filename_map = {
	["cmake_modules"] = "cmake",
	["cmake_module"] = "cmake",
	["CMakeLists.txt"] = "cmake",
}

local filetype_map = {
	["so"] = "dll",
	["sh"] = "bash",
}

--- @class ResolveRequest
--- @field is_dir boolean Indicates whether the file is a directory
--- @field path string Full path to the file
--- @field filename string File name
--- @field ft string? File type
--- @field is_open boolean True if folder is open (expanded in neo-tree)

--- @param opts ResolveRequest
function M.resolve(opts)
	local icon_name = ""

	-- Resolve by filename
	local type = filename_map[string.lower(opts.filename)]
	if type then
		icon_name = type
		goto finish
	end

	-- Resolve by FT
	if opts.ft then
		-- Remap as required
		type = filetype_map[opts.ft]
		if type then
			icon_name = type
			goto finish
		end

		icon_name = opts.ft
		goto finish
	end

	::finish::
	-- Even if no icon is found, return a plain directory icon
	if opts.is_dir then
		return icons.get_icon({
			name = icon_name,
			is_dir_open = opts.is_open,
		})
	end

	-- Plain icon
	if icon_name then
		return icons.get_icon({ name = icon_name })
	end
	return nil
end

HI_CACHE = {}

--- @param opts ResolveRequest
function M.resolve_with_fallback(opts)
	local result = M.resolve(opts)
	if result then return result end

	return { text = opts.ft or "NO", hi = "Normal" }
	--if opts.is_dir then
	--	return { text = (opts.is_open and " " or " "), hi = "NeoTreeFileIcon" }
	--end
	--local extension = opts.filename:match("%.([^./\\]+)$")
	--local text, color = require("nvim-web-devicons").get_icon_color(opts.filename, extension)
	--if not text then
	--	return {
	--		text = "󰈙 ", hi = "NeoTreeFileName"
	--	}
	--end

	---- Get or build highlight
	--local col_name = color:sub(2)
	--local hi = HI_CACHE[col_name]
	--if not hi then
	--	local name = "ColrIconsHi" .. col_name
	--	vim.api.nvim_set_hl(0, name, { fg = color })
	--	HI_CACHE[col_name] = name
	--	hi = name
	--end
	--return { text = text, hi = hi }
end

return M
