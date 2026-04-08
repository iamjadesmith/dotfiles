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

		local function get_obsidian_cwd()
			if vim.fn.has("macunix") == 1 then
				return vim.fn.expand("~/Library/Mobile Documents/iCloud~md~obsidian/Documents/Obsidian")
			end

			return vim.fn.expand("~/obsidian")
		end

		local obs_cwd = get_obsidian_cwd()

		local builtin = require("telescope.builtin")
		vim.keymap.set("n", "<leader>ff", builtin.find_files, { desc = "Find files" })
		vim.keymap.set("n", "<leader>fh", builtin.help_tags, { desc = "Search help tags" })
		vim.keymap.set("n", "<leader>fb", builtin.buffers, { desc = "Find buffers" })
		vim.keymap.set("n", "<leader>en", function()
			builtin.find_files({
				cwd = "~/.dotfiles/.config/nvim",
			})
		end, { desc = "Find Neovim config files" })
		vim.keymap.set("n", "<leader>edd", function()
			builtin.git_files({
				cwd = "~/.dotfiles",
			})
		end, { desc = "Find dotfiles (git files)" })
		vim.keymap.set("n", "<leader>edn", function()
			builtin.find_files({
				cwd = "~/.dotfiles/nix",
				find_command = { "rg", "--files", "--glob", "*.nix" },
			})
		end, { desc = "Find Nix files" })
		vim.keymap.set("n", "<leader>eo", function()
			builtin.find_files({
				cwd = obs_cwd,
				find_command = { "rg", "--files", "--glob", "*.md" },
			})
		end, { desc = "Find Obsidian notes" })

		require("config.telescope.multigrep").setup()
	end,
}
