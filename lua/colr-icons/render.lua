local M = {}

HI_CACHE = {}

--- @brief Get a highlight group for a foreground color
--- @param color string Color in this format: `#FF007F`
--- @return string Highlight group name for @p color
function M.get_hi(color)
	local col_name = color:sub(2)
	local hi = HI_CACHE[col_name]
	if hi then return hi end

	local name = "ColrIconsHi" .. col_name
	vim.api.nvim_set_hl(0, name, { fg = color })
	HI_CACHE[col_name] = name
	return name
end

return M
