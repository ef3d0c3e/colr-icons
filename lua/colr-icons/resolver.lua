local icons = require("colr-icons.icons")
local M = {}

-- Remap filetype
local ft_map = {
	["so"] = "dll",
}

--- @class ResolveFile
--- @field is_dir boolean Indicates whether the file is a directory
--- @field path string Full path to the file
--- @field filename string File name
--- @field ft string? File type
--- @field is_open boolean True if node is open (expanded in neo-tree)

--- @param opts ResolveFile
function M.resolve(opts)
	if opts.is_dir then
		local filename_lc = string.lower(opts.filename)

		local id = icons.ICONS_FOLDERS[filename_lc]
		if not id then return nil end
		return {
			text = icons.get_icon(id),
			hi = "Normal"
		}
	end

	-- Match filename
	local id = icons.ICONS_FILES[string.lower(opts.filename)]
	if id then return {
		text = icons.get_icon(id),
		hi = "Normal",
	} end

	-- Match by filetype
	local ft = opts.ft or vim.filetype.match({
		filename = opts.path,
	})
	ft = ft_map[ft] or ft
	id = icons.ICONS_FILES[ft]
	if id then
		return {
			text = icons.get_icon(id),
			hi = "Normal",
		}
	end
	return nil
end

HI_CACHE = {}

--- @param opts ResolveFile
function M.resolve_with_fallback(opts)
	local result = M.resolve(opts)
	if result then return result end

	if opts.is_dir then
		return { text = (opts.is_open and " " or " "), hi = "NeoTreeFileIcon" }
	end
	local extension = opts.filename:match("%.([^./\\]+)$")
	local text, color = require("nvim-web-devicons").get_icon_color(opts.filename, extension)
	if not text then
		return {
			text = "󰈙 ", hi = "NeoTreeFileName"
		}
	end

	-- Get or build highlight
	local hi = HI_CACHE[text]
	if not hi then
		local name = "ColrIconsHi" .. #HI_CACHE
		vim.api.nvim_set_hl(0, name, { fg = color })
		HI_CACHE[text] = name
		hi = name
	end
	return { text = text, hi = hi }
end

return M
