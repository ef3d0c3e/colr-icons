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
	local base_icon = ICONS[opts.name]

	-- Select the closest matching icon variations based on config.theme_selection
	local icon = nil
	if base_icon then
		for _, theme_name in ipairs(M.config.theme_selection) do
			icon = base_icon[theme_name]
			if icon then goto theme_icon_end end
		end
		::theme_icon_end::
	end

	-- Return icon + optional base
	if icon then
		if not opts.is_dir_open then
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

	if opts.with_placeholder == true then
		-- Return placeholder
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
