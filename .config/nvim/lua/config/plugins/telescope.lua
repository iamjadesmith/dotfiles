return {
	"nvim-telescope/telescope.nvim",
	tag = "v0.2.0",
	dependencies = {
		"nvim-lua/plenary.nvim",
		{ "nvim-telescope/telescope-fzf-native.nvim", build = "make" },
	},

	config = function()
		require("telescope").setup({
			extensions = {
				fzf = {},
			},
		})

		require("telescope").load_extension("fzf")

		local obs_cwd = "~/obsidian"

		local builtin = require("telescope.builtin")
		vim.keymap.set("n", "<leader>ff", builtin.find_files, {})
		vim.keymap.set("n", "<leader>fh", builtin.help_tags, {})
		vim.keymap.set("n", "<leader>fb", builtin.buffers, {})
		vim.keymap.set("n", "<leader>en", function()
			builtin.find_files({
				cwd = "~/.dotfiles/.config/nvim",
			})
		end)
		vim.keymap.set("n", "<leader>edd", function()
			builtin.git_files({
				cwd = "~/.dotfiles",
			})
		end)
		vim.keymap.set("n", "<leader>edn", function()
			builtin.find_files({
				cwd = "~/.dotfiles/nix",
				find_command = { "rg", "--files", "--glob", "*.nix" },
			})
		end)
		vim.keymap.set("n", "<leader>eo", function()
			builtin.find_files({
				cwd = obs_cwd,
				find_command = { "rg", "--files", "--glob", "*.md" },
			})
		end)

		require("config.telescope.multigrep").setup()
	end,
}
