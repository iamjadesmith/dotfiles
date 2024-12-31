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
			wk.add({
				{ "<leader>f", group = "Find" },
				{ "<leader>e", group = "Edit" },
				{ "<leader>s", desc = "Search Current Word" },
				{ "<leader>a", desc = "Add to Harpoon" },
			})
			wk.setup(opts)
		end,
	},
}
