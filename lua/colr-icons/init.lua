local M = {}

M.config = {
	integrations = { "neo_tree", "snacks_picker" },
	icons = {},
	resolver = {},
}

local integrations = {
	neo_tree = "colr-icons.integrations.neo_tree",
	snacks_picker = "colr-icons.integrations.snacks_picker",
}

function M.setup(opts)
	M.config = vim.tbl_deep_extend("force", M.config, opts or {})

	if not require("colr-icons.icons").setup(M.config.icons) then
		return
	end
	require("colr-icons.resolver").setup(M.config.resolver)

	for _, integration in ipairs(M.config.integrations) do
		if not integrations[integration] then
			vim.notify("[colr-icons] Invalid integration `" .. integration .."'", vim.log.levels.ERROR)
		end
		local module = require(integrations[integration])
		local setup_ok, result, err = pcall(module.setup)
		if not setup_ok then
			vim.notify("[colr-icons] Failed to setup integration `" .. integration .."'", vim.log.levels.ERROR)
		end
		if result == false then
			vim.notify("[colr-icons] Failed to setup integration `" .. integration .."': " .. err, vim.log.levels.ERROR)
		end
	end
end

return M
