local vault_path = vim.fn.expand("~/obsidian")
vim.g.last_work_buf = nil

local function toggle_obsidian()
	local current_buf = vim.api.nvim_get_current_buf()
	local current_name = vim.api.nvim_buf_get_name(current_buf)
	local current_ft = vim.api.nvim_get_option_value("filetype", { buf = current_buf })

	if current_name:find(vault_path, 1, true) == 1 and current_ft == "markdown" then
		if
			vim.g.last_work_buf
			and vim.api.nvim_buf_is_valid(vim.g.last_work_buf)
			and vim.api.nvim_buf_is_loaded(vim.g.last_work_buf)
		then
			vim.api.nvim_set_current_buf(vim.g.last_work_buf)
		else
			vim.cmd("b#")
		end
		return
	end

	vim.g.last_work_buf = current_buf

	local bufs = vim.api.nvim_list_bufs()
	for i = #bufs, 1, -1 do
		local bufnr = bufs[i]
		if vim.api.nvim_buf_is_loaded(bufnr) then
			local buf_name = vim.api.nvim_buf_get_name(bufnr)
			local buf_ft = vim.api.nvim_get_option_value("filetype", { buf = bufnr })
			if buf_name:find(vault_path, 1, true) == 1 and buf_ft == "markdown" then
				vim.api.nvim_set_current_buf(bufnr)
				return
			end
		end
	end

	local builtin = require("telescope.builtin")
	builtin.find_files({ cwd = vault_path, find_command = { "rg", "--files", "--glob", "*.md" } })
end

vim.keymap.set("n", "<leader>oo", toggle_obsidian, { desc = "Toggle to/from Obsidian buffer" })
