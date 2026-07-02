local icons = require("colr-icons.icons")

local M = {
	devicon = nil
}

M.config = {
	devicon_fallback = true,
}

--- @class ResolveRequest
--- @field is_dir boolean Indicates whether the file is a directory
--- @field path string? Full path to the file
--- @field filename string File name
--- @field ft string? File type
--- @field is_open boolean True if folder is open (expanded in neo-tree)

--- @class ResolveResult Result of a resolver call
--- @field text string The icon text
--- @field color string? Foreground color, e.g `#FF007F`


-- Map of filename -> icon
local filename_map = {
	["cmake_modules"] = "cmake",
	["cmake_module"] = "cmake",
	["CMakeLists.txt"] = "cmake",
	["docker-compose.yml"] = "docker-compose",
	["license"] = "license",
	["license.md"] = "license",
	["license.rst"] = "license",
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
	["sql"] = "database",
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

--- @param opts ResolveRequest The request
--- @return ResolveResult? The response on success, field `color` is empty because icons carry their own colors
function M.resolve(opts)
	local icon_name = ""

	-- Resolve by filename
	local filename_lower = string.lower(opts.filename)
	local type = filename_map[filename_lower]
	local ext = filename_lower:match("%.([^./\\]+)$")
	if type then
		icon_name = type
		goto finish
	end

	-- Resolve by FT
	if opts.ft then
		-- Special handling for C/C++ headers
		if (opts.ft == "c" or opts.ft == "cpp") and ext == "h" then
			icon_name = "c-header"
			goto finish
		elseif opts.ft == "cpp" and (ext == "hpp" or ext == "tpp") then
			icon_name = "cpp-header"
			goto finish
		end
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

--- @brief Resolve an icon request, (optionally) using nvim-web-devicon as a fallback, otherwise return a placeholder icon
--- @param opts ResolveRequest The request
--- @return ResolveResult
function M.resolve_with_fallback(opts)
	local result = M.resolve(opts)
	if result then return result end

	-- DEBUG: return { text = opts.ft or "NO" }

	-- Devicon fallback
	if M.devicon then
		local extension = string.lower(opts.filename):match("%.([^./\\]+)$")
		local text, color = M.devicon.get_icon_color(opts.filename, extension)
		if not text then
			return { text = "󰈙 " }
		end

		return { text = text, color = color }
	end
	return { text = "󰈙 " }
end

function M.setup(opts)
	M.config = vim.tbl_deep_extend("force", M.config, opts or {})

	if M.config.devicon_fallback == true then
		local ok, result = pcall(require, "nvim-web-devicon")
		if ok then
			M.devicon = result
		end
	end
end

return M
