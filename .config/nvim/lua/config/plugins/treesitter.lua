return {
	{
		"nvim-treesitter/nvim-treesitter",
		build = ":TSUpdate",
		config = function()
			require("nvim-treesitter").setup({
				ensure_installed = {
					"c",
					"lua",
					"vim",
					"vimdoc",
					"query",
					"markdown",
					"markdown_inline",
					"yaml",
					"rust",
					"r",
					"rnoweb",
					"python",
					"bash",
					"nix",
				},
				auto_install = true,
			})
		end,
	},
}
