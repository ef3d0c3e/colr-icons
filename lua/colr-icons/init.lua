local M = {}

local integrations = {
	neo_tree = "colr-icons.integrations.neo_tree",
}

function M.setup(opts)
	if not require("colr-icons.icons").setup(opts.icons) then
		return
	end
	require(integrations.neo_tree).setup()
end

return M
