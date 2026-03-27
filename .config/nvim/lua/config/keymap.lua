vim.g.mapleader = " "
vim.g.maplocalleader = "\\"
vim.g.netrw_browse_split = 0
vim.g.netrw_banner = 0
vim.g.netrw_winsize = 25

vim.g.clipboard = {
	name = "OSC 52",
	copy = {
		["+"] = require("vim.ui.clipboard.osc52").copy("+"),
		["*"] = require("vim.ui.clipboard.osc52").copy("*"),
	},
	paste = {
		["+"] = require("vim.ui.clipboard.osc52").paste("+"),
		["*"] = require("vim.ui.clipboard.osc52").paste("*"),
	},
}

vim.keymap.set("n", "<leader><leader>x", "<cmd>source %<CR>", { desc = "Source current file" })
vim.keymap.set("n", "<leader>x", ":.lua<CR>", { desc = "Execute current line" })
vim.keymap.set("v", "<leader>x", ":lua<CR>", { desc = "Execute selection" })

vim.keymap.set("v", "J", ":m '>+1<CR>gv=gv", { desc = "Move selection down" })
vim.keymap.set("v", "K", ":m '<-2<CR>gv=gv", { desc = "Move selection up" })
vim.keymap.set("n", "J", "mzJ`z", { desc = "Join lines and keep cursor" })
vim.keymap.set("n", "<C-d>", "<C-d>zz", { desc = "Half-page down (centered)" })
vim.keymap.set("n", "<C-u>", "<C-u>zz", { desc = "Half-page up (centered)" })
vim.keymap.set("n", "n", "nzzzv", { desc = "Next search result (centered)" })
vim.keymap.set("n", "N", "Nzzzv", { desc = "Previous search result (centered)" })

vim.keymap.set("x", "<leader>p", [["_dP]], { desc = "Paste without yanking" })
vim.keymap.set({ "n", "v" }, "<leader>y", [["+y]], { desc = "Yank to system clipboard" })
vim.keymap.set("n", "<leader>Y", [["+Y]], { desc = "Yank line to system clipboard" })
vim.keymap.set({ "n", "v" }, "<leader>d", [["_d]], { desc = "Delete to black hole register" })
vim.keymap.set("n", "Q", "<nop>", { desc = "Disable Ex mode" })

vim.keymap.set("i", "<C-c>", "<Esc>", { desc = "Escape insert mode" })
vim.keymap.set("n", "<leader>s", [[:%s/\<<C-r><C-w>\>/<C-r><C-w>/gI<Left><Left><Left>]], { desc = "Substitute word under cursor" })

vim.keymap.set("n", "<leader>t", "<cmd>Floaterminal<CR>", { desc = "Toggle floating terminal" })
vim.keymap.set("n", "<leader>os", "<cmd>!obs_sync<CR>", { desc = "Sync Obsidian vault" })
