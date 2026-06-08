local function theme_mode()
	local mode_file = vim.fn.expand("~/.config/theme-mode")
	local ok, lines = pcall(vim.fn.readfile, mode_file)
	if ok and (lines[1] == "dark" or lines[1] == "light") then
		return lines[1]
	end

	return "dark"
end

local function write_theme_mode(mode)
	local config_dir = vim.fn.expand("~/.config")
	vim.fn.mkdir(config_dir, "p")
	vim.fn.writefile({ mode }, config_dir .. "/theme-mode")
end

local function apply_theme()
	if theme_mode() == "light" then
		vim.o.background = "light"
		vim.cmd.colorscheme("catppuccin-latte")
	else
		vim.o.background = "dark"
		vim.cmd.colorscheme("tokyonight-night")
	end
end

return {
	{
		"folke/tokyonight.nvim",
		lazy = false,
		priority = 1000,
		config = function()
			if theme_mode() == "dark" then
				apply_theme()
			end
		end,
	},
	{
		"catppuccin/nvim",
		name = "catppuccin",
		lazy = false,
		priority = 1000,
		config = function()
			if theme_mode() == "light" then
				apply_theme()
			end

			vim.api.nvim_create_user_command("ThemeDark", function()
				write_theme_mode("dark")
				apply_theme()
			end, {})

			vim.api.nvim_create_user_command("ThemeLight", function()
				write_theme_mode("light")
				apply_theme()
			end, {})

			vim.api.nvim_create_user_command("ThemeToggle", function()
				if theme_mode() == "dark" then
					write_theme_mode("light")
				else
					write_theme_mode("dark")
				end

				apply_theme()
			end, {})

			vim.api.nvim_create_user_command("ThemeReload", apply_theme, {})

			vim.api.nvim_create_autocmd("FocusGained", {
				group = vim.api.nvim_create_augroup("jade-theme", { clear = true }),
				callback = apply_theme,
			})
		end,
	},
}
