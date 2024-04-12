local plugins = {
	{
		"R-nvim/R.nvim",
		config = function()
			-- Create a table with the options to be passed to setup()
			local opts = {
				R_args = { "--quiet", "--no-save" },
				hook = {
					after_config = function()
						-- This function will be called at the FileType event
						-- of files supported by R.nvim. This is an
						-- opportunity to create mappings local to buffers.
						if vim.o.syntax ~= "rbrowser" then
							vim.api.nvim_buf_set_keymap(0, "n", "<Enter>", "<Plug>RDSendLine", {})
							vim.api.nvim_buf_set_keymap(0, "v", "<Enter>", "<Plug>RSendSelection", {})
						end
					end,
				},
				min_editor_width = 72,
				rconsole_width = 78,
				disable_cmds = {
					"RClearConsole",
					"RCustomStart",
					"RSPlot",
					"RSaveClose",
				},
			}
			-- Check if the environment variable "R_AUTO_START" exists.
			-- If using fish shell, you could put in your config.fish:
			-- alias r "R_AUTO_START=true nvim"
			if vim.env.R_AUTO_START == "true" then
				opts.auto_start = 1
				opts.objbr_auto_start = true
			end
			require("r").setup(opts)
		end,
		lazy = false,
	},
	"equalsraf/neovim-gui-shim",
	{
		"iamcco/markdown-preview.nvim",
		cmd = { "MarkdownPreviewToggle", "MarkdownPreview", "MarkdownPreviewStop" },
		ft = { "markdown" },
		build = function()
			vim.fn["mkdp#util#install"]()
		end,
	},
	{
	'kristijanhusak/vim-dadbod-ui',
	dependencies = {
	  { 'tpope/vim-dadbod', lazy = true },
	  { 'kristijanhusak/vim-dadbod-completion', ft = { 'sql', 'mysql', 'plsql' }, lazy = true },
	},
	cmd = {
	  'DBUI',
	  'DBUIToggle',
	  'DBUIAddConnection',
	  'DBUIFindBuffer',
	},
	init = function()
	  -- Your DBUI configuration
	  vim.g.db_ui_use_nerd_fonts = 1
	end,
	}
}
return plugins
