local icons = require("colr-icons.icons")
local M = {}


-- Map of filename -> icon
local filename_map = {
	["cmake_modules"] = "cmake",
	["cmake_module"] = "cmake",
	["CMakeLists.txt"] = "cmake",
	["docker-compose.yml"] = "docker-compose",
}

-- Map of filetype -> icon
local filetype_map = {
	["so"] = "dll",
	["sh"] = "bash",
	["dosbatch"] = "batch",
	["jsonc"] = "json",
	["cmakecache"] = "cmake",
	["make"] = "makefile",
	["dockerfile"] = "docker",
	["xpm"] = "image",
}

-- Map of extension -> icon
local ext_map = {
	["png"] = "image",
	["jpg"] = "image",
	["jpeg"] = "image",
	["gif"] = "image",
	["webp"] = "image",
	["xcf"] = "image",
	["kra"] = "image",

	["ogg"] = "audio",
	["mp3"] = "audio",
	["flac"] = "audio",
	["wav"] = "audio",

	["mkv"] = "video",
	["mp4"] = "video",
	["m4a"] = "video",
	["webm"] = "video",

	["tar"] = "zip",
	["gz"] = "zip",
	["xz"] = "zip",
	["a"] = "zip",

	["out"] = "binary",
	["o"] = "binary",

	["so"] = "dll",
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
	local filename_lower = string.lower(opts.filename)
	local type = filename_map[filename_lower]
	local ext = nil
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

		-- Placeholder
		if opts.ft then
			icon_name = opts.ft
			goto finish
		end
	end

	-- Resolve by extension
	ext = filename_lower:match("%.([^./\\]+)$")
	if ext then
		type = ext_map[ext]
		if type then
			icon_name = type
			goto finish
		end
	end

	icon_name = filename_lower

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
