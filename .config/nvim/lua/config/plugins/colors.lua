-- Nvim sets 'background' from the terminal's background color at startup and
-- again whenever the terminal reports a theme change (DEC mode 2031), so the
-- colorscheme follows the terminal, including over SSH and inside tmux.
local themes = {
	dark = "tokyonight-night",
	light = "catppuccin-latte",
}

local function apply_theme()
	local scheme = themes[vim.o.background] or themes.dark
	-- Colorschemes set 'background' themselves; skip when already applied so
	-- the OptionSet autocmd below does not loop.
	if vim.g.colors_name ~= scheme then
		vim.cmd.colorscheme(scheme)
	end
end

local function set_background(mode)
	vim.o.background = mode
	apply_theme()
end

return {
	{
		"folke/tokyonight.nvim",
		lazy = false,
		priority = 1000,
	},
	{
		"catppuccin/nvim",
		name = "catppuccin",
		lazy = false,
		priority = 1000,
		dependencies = { "folke/tokyonight.nvim" },
		config = function()
			apply_theme()

			vim.api.nvim_create_autocmd("OptionSet", {
				group = vim.api.nvim_create_augroup("dotfiles_theme", { clear = true }),
				pattern = "background",
				callback = apply_theme,
			})

			-- Manual overrides last until the terminal next reports a theme change.
			vim.api.nvim_create_user_command("ThemeDark", function()
				set_background("dark")
			end, {})

			vim.api.nvim_create_user_command("ThemeLight", function()
				set_background("light")
			end, {})

			vim.api.nvim_create_user_command("ThemeToggle", function()
				set_background(vim.o.background == "dark" and "light" or "dark")
			end, {})

			-- Ask the terminal for its background color again; Nvim updates
			-- 'background' from the reply.
			vim.api.nvim_create_user_command("ThemeReload", function()
				vim.api.nvim_ui_send("\027]11;?\007")
			end, {})
		end,
	},
}
