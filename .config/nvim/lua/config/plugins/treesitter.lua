return {
	{
		"nvim-treesitter/nvim-treesitter",
		lazy = false,
		build = ":TSUpdate",
		config = function()
			local ts = require("nvim-treesitter")
			ts.setup({})
			ts.install({
				"bash",
				"c",
				"lua",
				"markdown",
				"markdown_inline",
				"nix",
				"python",
				"query",
				"r",
				"rnoweb",
				"rust",
				"vim",
				"vimdoc",
				"yaml",
			})
			vim.api.nvim_create_autocmd("FileType", {
				group = vim.api.nvim_create_augroup("treesitter-start", { clear = true }),
				callback = function(args)
					pcall(vim.treesitter.start, args.buf)
				end,
			})
		end,
	},
}
