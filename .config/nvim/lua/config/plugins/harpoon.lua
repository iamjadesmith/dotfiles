return {
	{
		"ThePrimeagen/harpoon",
		branch = "harpoon2",
		dependencies = { "nvim-lua/plenary.nvim" },
		config = function()
			local harpoon = require("harpoon")

			harpoon:setup()

			vim.keymap.set("n", "<leader>a", function()
				harpoon:list():add()
			end, { desc = "Add file to Harpoon" })
			vim.keymap.set("n", "<C-e>", function()
				harpoon.ui:toggle_quick_menu(harpoon:list())
			end, { desc = "Toggle Harpoon menu" })

			vim.keymap.set("n", "<C-h>", function()
				harpoon:list():select(1)
			end, { desc = "Go to Harpoon file 1" })
			vim.keymap.set("n", "<C-j>", function()
				harpoon:list():select(2)
			end, { desc = "Go to Harpoon file 2" })
			vim.keymap.set("n", "<C-k>", function()
				harpoon:list():select(3)
			end, { desc = "Go to Harpoon file 3" })
			vim.keymap.set("n", "<C-l>", function()
				harpoon:list():select(4)
			end, { desc = "Go to Harpoon file 4" })

			vim.keymap.set("n", "<C-S-P>", function()
				harpoon:list():prev()
			end, { desc = "Go to previous Harpoon file" })
			vim.keymap.set("n", "<C-S-N>", function()
				harpoon:list():next()
			end, { desc = "Go to next Harpoon file" })
		end,
	},
}
