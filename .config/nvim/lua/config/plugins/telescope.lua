return {
	"nvim-telescope/telescope.nvim",
	tag = "0.1.8",
	dependencies = {
		"nvim-lua/plenary.nvim",
	},

	config = function()
		require("telescope").setup({})

		local builtin = require("telescope.builtin")
		vim.keymap.set("n", "<leader>ff", builtin.find_files, {})
		vim.keymap.set("n", "<leader>fh", builtin.help_tags, {})
		vim.keymap.set("n", "<leader>fb", builtin.buffers, {})
		vim.keymap.set("n", "<leader>en", function()
			builtin.find_files({
				cwd = vim.fn.stdpath("config"),
			})
		end)
		vim.keymap.set("n", "<leader>ed", function()
			builtin.find_files({
				cwd = "~/.dotfiles",
			})
		end)
		vim.keymap.set("n", "<leader>eo", function()
			builtin.find_files({
				cwd = "~/Obsidian",
			})
		end)

		require("config.telescope.multigrep").setup()
	end,
}
