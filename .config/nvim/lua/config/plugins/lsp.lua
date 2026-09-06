return {
	{
		"milanglacier/minuet-ai.nvim",
		event = "InsertEnter",
		config = function()
			require("minuet").setup({
				provider = "openai_fim_compatible",
				n_completions = 1,
				context_window = 4096,
				throttle = 1000,
				debounce = 300,
				request_timeout = 3,
				virtualtext = {
					auto_trigger_ft = { "*" },
					auto_trigger_ignore_ft = { "TelescopePrompt", "lazy", "oil" },
					keymap = {
						next = "<M-]>",
						prev = "<M-[>",
					},
				},
				provider_options = {
					openai_fim_compatible = {
						api_key = function()
							return "ollama"
						end,
						name = "Ollama",
						end_point = "http://mjolnir.joejad.lan:11434/v1/completions",
						model = "qwen2.5-coder:7b",
						optional = {
							max_tokens = 64,
							top_p = 0.9,
						},
					},
				},
			})

			local virtualtext = require("minuet.virtualtext")
			vim.keymap.set("i", "<Tab>", function()
				if virtualtext.action.is_visible() then
					virtualtext.action.accept()
					return ""
				end
				return "<Tab>"
			end, { expr = true, silent = true, desc = "Accept AI completion or insert tab" })
		end,
	},
	{
		"neovim/nvim-lspconfig",
		dependencies = {
			"hrsh7th/cmp-nvim-lsp",
			"hrsh7th/cmp-buffer",
			"hrsh7th/cmp-path",
			"hrsh7th/cmp-cmdline",
			"hrsh7th/nvim-cmp",
			"L3MON4D3/LuaSnip",
			"saadparwaiz1/cmp_luasnip",
			"j-hui/fidget.nvim",
			"R-nvim/cmp-r",
		},

		config = function()
			local cmp = require("cmp")
			local cmp_lsp = require("cmp_nvim_lsp")
			local opts = { noremap = true, silent = true }
			local on_attach = function(_, bufnr)
				local keymap_opts = vim.tbl_extend("force", opts, { buffer = bufnr })
				vim.keymap.set(
					"n",
					"<leader>d",
					vim.diagnostic.open_float,
					vim.tbl_extend("force", keymap_opts, { desc = "Show line diagnostics" })
				)
				vim.keymap.set(
					"n",
					"K",
					vim.lsp.buf.hover,
					vim.tbl_extend("force", keymap_opts, { desc = "Show hover documentation" })
				)
			end

			local python_on_attach = function(client, bufnr)
				if client.name == "ruff" then
					client.server_capabilities.hoverProvider = false
				end
				on_attach(client, bufnr)
			end
			local capabilities = vim.tbl_deep_extend(
				"force",
				{},
				vim.lsp.protocol.make_client_capabilities(),
				cmp_lsp.default_capabilities()
			)
			capabilities.general = capabilities.general or {}
			capabilities.general.positionEncodings = { "utf-16" }

			require("fidget").setup({})

			vim.lsp.config("lua_ls", {
				settings = {
					Lua = {
						diagnostics = {
							globals = { "vim", "it", "describe", "before_each", "after_each" },
						},
					},
				},
			})
			vim.lsp.config("r_language_server", {})
			vim.lsp.config("rust_analyzer", {})
			vim.lsp.config("basedpyright", {
				on_attach = python_on_attach,
				capabilities = capabilities,
			})
			vim.lsp.config("ruff", {
				on_attach = python_on_attach,
				capabilities = capabilities,
			})
			vim.lsp.config("nil_ls", {})
			vim.lsp.config("yamlls", {
				capabilities = capabilities,
				filetypes = { "yaml" },
			})
			vim.lsp.config("jsonls", {
				capabilities = capabilities,
			})
			vim.lsp.config("lemminx", {
				capabilities = capabilities,
				filetypes = { "xml", "xsd", "xslt", "svg" },
			})

			vim.lsp.enable("r_language_server")
			vim.lsp.enable("rust_analyzer")
			vim.lsp.enable("basedpyright")
			vim.lsp.enable("ruff")
			vim.lsp.enable("lua_ls")
			vim.lsp.enable("nil_ls")
			vim.lsp.enable("yamlls")
			vim.lsp.enable("jsonls")
			vim.lsp.enable("lemminx")

			local cmp_select = { behavior = cmp.SelectBehavior.Select }

			cmp.setup({
				snippet = {
					expand = function(args)
						require("luasnip").lsp_expand(args.body)
						require("cmp_r")
					end,
				},
				mapping = cmp.mapping.preset.insert({
					["<C-p>"] = cmp.mapping.select_prev_item(cmp_select),
					["<C-n>"] = cmp.mapping.select_next_item(cmp_select),
					["<C-y>"] = cmp.mapping.confirm({ select = true }),
					["<C-Space>"] = cmp.mapping.complete(),
				}),
				sources = cmp.config.sources({
					{ name = "nvim_lsp" },
					{ name = "cmp_r" },
					{ name = "vim-dadbod-completion" },
					{ name = "luasnip" },
				}, {
					{ name = "buffer" },
				}),
			})

			vim.diagnostic.config({
				float = {
					focusable = false,
					style = "minimal",
					border = "rounded",
					source = "always",
					header = "",
					prefix = "",
				},
			})
		end,
	},
}
