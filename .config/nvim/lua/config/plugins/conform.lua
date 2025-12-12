return {
	"stevearc/conform.nvim",
	event = { "BufWritePre" },
	cmd = { "ConformInfo" },
	keys = {
		{
			"<leader>b",
			function()
				require("conform").format({ lsp_fallback = "true", timeout_ms = 2000 })
			end,
			mode = "",
			desc = "Format buffer",
		},
	},
	opts = {
		formatters = {
			my_styler = {
				command = "R",
				args = { "-s", "-e", "styler::style_file(commandArgs(TRUE))", "--args", "$FILENAME" },
				stdin = false,
			},
		},
		notify_on_error = false,
		formatters_by_ft = {
			lua = { "stylua" },
			python = { "pyright" },
			r = { "my_styler" },
			quarto = { "my_styler" },
			rust = { "rustfmt" },
			nix = { "nixfmt" },
		},
		format_on_save = {
			lsp_format = "fallback",
			timeout_ms = 2000,
		},
	},
}
