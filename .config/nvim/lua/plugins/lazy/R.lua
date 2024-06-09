return {
	{
		"R-nvim/R.nvim",
		config = function()
			local opts = {
				R_args = { "--quiet", "--no-save" },
				hook = {
					after_config = function()
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
			if vim.env.R_AUTO_START == "true" then
				opts.auto_start = 1
				opts.objbr_auto_start = true
			end
			require("r").setup(opts)
		end,
		lazy = false,
	},
}
