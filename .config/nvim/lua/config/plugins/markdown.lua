return {
	"MeanderingProgrammer/render-markdown.nvim",
	ft = { "markdown" },
	dependencies = {
		"nvim-treesitter/nvim-treesitter",
		"echasnovski/mini.nvim",
	},
	keys = {
		{ "<leader>mp", "<cmd>RenderMarkdown preview<cr>", desc = "Preview Markdown" },
		{ "<leader>mt", "<cmd>RenderMarkdown toggle<cr>", desc = "Toggle Markdown Rendering" },
	},
	opts = {
		preset = "obsidian",
		latex = {
			enabled = false,
		},
	},
}
