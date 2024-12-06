return {
    "stevearc/conform.nvim",
    event = { "BufWritePre" },
    cmd = { "ConformInfo" },
    keys = {
        {
            "<leader>f",
            function()
                require("conform").format({lsp_fallback = "true", timeout_ms = 2000})
            end,
            mode = "",
            desc = "Format buffer",
        },
    },
    opts = {
        notify_on_error = false,
        formatters_by_ft = {
            lua = { "stylua" },
            nix = { "nixfmt" },
            python = { "black" },
            r = { "styler" },
            swift = { "swiftformat" },
        },
    },
}
