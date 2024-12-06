return {
	"nvim-treesitter/nvim-treesitter",
	build = ":TSUpdate",
	require("nvim-treesitter.configs").setup({
		ensure_installed = {
			"vimdoc",
			"javascript",
			"typescript",
			"markdown",
			"markdown_inline",
			"query",
			"c",
			"lua",
			"rust",
			"jsdoc",
			"bash",
			"r",
			"python",
			"swift",
		},

		sync_install = false,
		auto_install = true,

		highlight = {
			enable = true,
			additional_vim_regex_highlighting = false,
		},
	}),
}
