return {
	"stevearc/oil.nvim",
	---@module 'oil'
	---@type oil.SetupOpts
	opts = {},
	dependencies = { { "echasnovski/mini.icons", opts = {} } },

	vim.keymap.set("n", "<leader>fd", "<cmd>Oil<CR>"),
}
