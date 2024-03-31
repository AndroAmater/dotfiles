return {
	"mhartington/formatter.nvim",
	config = function()
		require("formatter").setup({
			logging = true,
			log_level = vim.log.levels.WARN,
			-- All formatter configurations are opt-in
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
				["*"] = {
					-- "formatter.filetypes.any" defines default configurations for any
					-- filetype
					require("formatter.filetypes.any").remove_trailing_whitespace,
				},
			},
		})
	end,
}
