return {
	{
		"echasnovski/mini.nvim",
		config = function(_, opts)
			require("mini.icons").setup(opts)
		end,
	},
	{
		"folke/which-key.nvim",
		event = "VeryLazy",
		config = function(_, opts)
			local wk = require("which-key")
			wk.setup(opts)
			wk.add({
				{ "<leader>f", group = "Find" },
				{ "<leader>e", group = "Edit" },
				{ "<leader>s", desc = "Search Current Word" },
				{ "<leader>a", desc = "Add to Harpoon" },
			})
		end,
	},
}
