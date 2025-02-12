local dark_mode = true

return {
	{
		"folke/tokyonight.nvim",
		lazy = false,
		priority = 1000,
		config = function()
			if dark_mode then
				vim.cmd.colorscheme("tokyonight-night")
			end
		end,
	},
	{
		"catppuccin/nvim",
		name = "catppuccin",
		lazy = false,
		priority = 1000,
		config = function()
			if not dark_mode then
				vim.cmd.colorscheme("catppuccin-latte")
			end
		end,
	},
}
