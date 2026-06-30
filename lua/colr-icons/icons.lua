local M = {
}

ICONS = require("colr-icons.table")

M.config = {
	theme_selection = {
		"catpuccin-frappe",
		"material",
	}
}

M.themes = {
	["material"] = {
		folder_closed = "󲆊",
		folder_open = "󲆊",
		placeholder = "FF",
	},
	["catpuccin-frappe"] = {
		folder_closed = "󲆋",
		folder_open = "󲆌",
		placeholder = "FF",
	},
	["catpuccin-latte"] = {
		folder_closed = "󲆍",
		folder_open = "󲆎",
		placeholder = "FF",
	},
	["catpuccin-macchiato"] = {
		folder_closed = "󲆏",
		folder_open = "󲆐",
		placeholder = "FF",
	},
	["catpuccin-mocha"] = {
		folder_closed = "󲆑",
		folder_open = "󲆒",
		placeholder = "FF",
	},
}

--- @class IconRequest
--- @field name string Icon name
--- @field is_dir_open boolean? `nil` if regular file, `false` if closed folder, `true` if open folder
--- @field with_placeholder boolean? Set to true if you want to return a placeholder

--- @brief Get an icon
--- @param opts IconRequest
--- @return table? containing {text, hi?}
function M.get_icon(opts)
	local icon = nil

	-- Try to find a direct folder icon, do not fallback
	local function direct_match(name)
		local theme_name = M.config.theme_selection[1]
		local icon_name = "folder_" .. name
		if opts.is_dir_open == true and theme_name ~= "material" then
			icon_name = icon_name .. "_open"
		end
		local base = ICONS[icon_name]
		if base then
			icon = base[theme_name]
			if icon then
				return { text = icon .. " " }
			end
		end
		return nil
	end
	if opts.is_dir_open ~= nil then
		local name = string.lower(opts.name)
		icon = direct_match(name)
		if not icon and name:sub(-1) == "s" then
			icon = direct_match(name:sub(1, -2))
		end

		if icon then return icon end
	end


	-- Select the closest matching icon variations based on config.theme_selection
	local base_icon = ICONS[opts.name]
	if base_icon then
		for _, theme_name in ipairs(M.config.theme_selection) do
			icon = base_icon[theme_name]
			if icon then goto theme_icon_end end
		end
		::theme_icon_end::
	end

	-- Return icon + optional base
	if icon then
		if opts.is_dir_open == nil then
			return { text = icon .. " " }
		end

		local theme = M.themes[M.config.theme_selection[1]]
		if opts.is_dir_open == true then
			return { text = theme.folder_open .. icon }
		else
			return { text = theme.folder_closed .. icon }
		end
	end

	-- No icon found, return plain directory
	if opts.is_dir_open == true then
		return { text = ICONS["folder-open"][M.config.theme_selection[1]] .. " " }
	elseif opts.is_dir_open == false then
		return { text = ICONS["folder"][M.config.theme_selection[1]] .. " " }
	end

	-- Return placeholder
	if opts.with_placeholder == true then
		local theme = M.themes[M.config.theme_selection[1]]
		-- TODO: Return devicon placeholder + hi
		return { text = theme.placeholder }
	end
	return nil
end

function M.setup(opts)
	vim.tbl_deep_extend("force", M.config, opts or {})
	if #M.config.theme_selection < 1 then
		vim.notify("Missing theme_selection", vim.log.levels.ERROR)
		return false
	end
	for _, theme_name in ipairs(M.config.theme_selection) do
		if not M.themes[theme_name] then
			vim.notify("Invalid icon theme `" .. theme_name .."'", vim.log.levels.ERROR)
			return false
		end
	end
	return true
end

return M
