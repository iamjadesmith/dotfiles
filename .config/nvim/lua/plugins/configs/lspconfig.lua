local lspconfig = require("lspconfig")

lspconfig.lua_ls.setup({
	settings = {
		Lua = {
			diagnostics = {
				globals = { "vim" },
				disable = { "different-requires" },
			},
		},
	},
})

lspconfig.rust_analyzer.setup({
	cargo = {
		features = { "all" },
	},
})

lspconfig.gopls.setup({
	filetypes = { "go", "gomod", "gowork", "gotmpl" },
})

lspconfig.r_language_server.setup({
	on_attach = on_attach,
	capabilities = capabilities,
})

lspconfig.sqls.setup({
	on_attach = on_attach,
	settings = {
		sqls = {
			connections = {
				{
					driver = "mssql",
					dataSourceName = "PModProdSQL\\PriceModelProd",
				},
				{
					driver = "mssql",
					dataSourceName = "Actuary-SQL\\Actuary",
				},
				{
					driver = "mssql",
					dataSourceName = "DMProd",
				},
			},
		},
	},
})
