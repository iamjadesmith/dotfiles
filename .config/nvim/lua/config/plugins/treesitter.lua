return {
	{
		"nvim-treesitter/nvim-treesitter",
		build = ":TSUpdate",
		lazy = false,
		branch = "master",
		main = "nvim-treesitter.configs",
		opts = {
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
			highlight = {
				enable = true,
			},
		},
	},
}
