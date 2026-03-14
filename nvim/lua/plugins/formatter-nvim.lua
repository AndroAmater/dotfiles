return {
	"mhartington/formatter.nvim",
	config = function()
		local util = require("formatter.util")
		local augroup = vim.api.nvim_create_augroup
		local autocmd = vim.api.nvim_create_autocmd

		local function current_buffer_dir()
			return vim.fn.fnamemodify(util.get_current_buffer_file_path(), ":p:h")
		end

		local function oxfmt()
			return {
				exe = "oxfmt",
				args = {
					"--stdin-filepath=" .. util.escape_path(util.get_current_buffer_file_path()),
				},
				stdin = true,
				cwd = current_buffer_dir(),
				try_node_modules = true,
			}
		end

		local function oxlint(extra_args)
			return function()
				local args = {
					"--fix",
					"--silent",
				}

				if extra_args then
					vim.list_extend(args, extra_args)
				end

				return {
					exe = "oxlint",
					args = args,
					stdin = false,
					cwd = current_buffer_dir(),
					try_node_modules = true,
					ignore_exitcode = true,
				}
			end
		end

		local oxlint_fix = oxlint()
		local oxlint_react = oxlint({ "--react-plugin" })
		local oxlint_vue = oxlint({ "--vue-plugin" })

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
					oxlint_fix,
					oxfmt,
				},
				javascriptreact = {
					oxlint_react,
					oxfmt,
				},
				typescript = {
					oxlint_fix,
					oxfmt,
				},
				typescriptreact = {
					oxlint_react,
					oxfmt,
				},
				vue = {
					oxlint_vue,
					oxfmt,
				},
				json = {
					oxfmt,
				},
				md = {
					oxfmt,
				},
				markdown = {
					oxfmt,
				},
				php = {
					require("formatter.filetypes.php").pint,
				},
				html = {
					oxfmt,
				},
				["*"] = {
					require("formatter.filetypes.any").remove_trailing_whitespace,
				},
			},
		})
	end,
}
