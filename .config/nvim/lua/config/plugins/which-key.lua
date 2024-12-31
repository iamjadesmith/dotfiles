return {
	{
		"echasnovski/mini.nvim",
		config = function(_, opts)
			require("mini.icons").setup(opts)
		end,
	},
	{
		"folke/which-key.nvim",
		keys = { "<leader>", "<c-r>", "<c-w>", '"', "'", "`", "c", "v", "g" },
		cmd = "WhichKey",
		config = function(_, opts)
			local wk = require("which-key")
			wk.setup(opts)
		end,
	},
}
