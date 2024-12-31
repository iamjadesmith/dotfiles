local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
	vim.fn.system({
		"git",
		"clone",
		"--filter=blob:none",
		"https://github.com/folke/lazy.nvim.git",
		"--branch=stable",
		lazypath,
	})
end
vim.opt.runtimepath:prepend(lazypath)

require("config.keymap")

require("lazy").setup({
	spec = {
		{
			"folke/tokyonight.nvim",
			config = function()
				vim.cmd.colorscheme("tokyonight-night")
			end,
		},
		{ import = "config.plugins" },
	},
	change_detection = {
		enabled = false,
		notify = false,
	},
})
