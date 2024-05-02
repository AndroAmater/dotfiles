return {
	"mhartington/formatter.nvim",
	config = function()
		local augroup = vim.api.nvim_create_augroup
		local autocmd = vim.api.nvim_create_autocmd
		augroup("__formatter__", { clear = true })
		autocmd("BufWritePost", {
			group = "__formatter__",
			command = ":FormatWrite",
		})

		require("formatter").setup({
			logging = true,
			log_level = vim.log.levels.WARN,
			filetype = {
				lua = {
					require("formatter.filetypes.lua").stylua,
				},
				javascript = {
					require("formatter.filetypes.typescript").eslint_d,
					require("formatter.filetypes.typescript").prettierd,
				},
				typescript = {
					require("formatter.filetypes.typescript").eslint_d,
					require("formatter.filetypes.typescript").prettierd,
				},
				vue = {
					require("formatter.filetypes.typescript").eslint_d,
					require("formatter.filetypes.typescript").prettierd,
				},
				json = {
					require("formatter.filetypes.typescript").eslint_d,
					require("formatter.filetypes.typescript").prettierd,
				},
				php = {
					require("formatter.filetypes.php").pint,
					require("formatter.filetypes.php").phpstan,
					require("formatter.filetypes.php").phpmd,
					require("formatter.filetypes.php").phpcs,
				},
				["*"] = {
					require("formatter.filetypes.any").remove_trailing_whitespace,
				},
			},
		})
	end,
}
