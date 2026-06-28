local M = {}

local integrations = {
	neo_tree = "colr-icons.integrations.neo_tree",
}

function M.setup(opts)

	require(integrations.neo_tree).setup()
end

return M
