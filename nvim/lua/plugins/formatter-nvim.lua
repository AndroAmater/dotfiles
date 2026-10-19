-- return {
-- 	"mhartington/formatter.nvim",
-- 	config = function()
-- 		local util = require("formatter.util")
-- 		local augroup = vim.api.nvim_create_augroup
-- 		local autocmd = vim.api.nvim_create_autocmd

-- 		local function current_buffer_dir()
-- 			return vim.fn.fnamemodify(util.get_current_buffer_file_path(), ":p:h")
-- 		end

-- 		local function oxfmt()
-- 			return {
-- 				exe = "oxfmt",
-- 				args = {
-- 					"--stdin-filepath=" .. util.escape_path(util.get_current_buffer_file_path()),
-- 				},
-- 				stdin = true,
-- 				cwd = current_buffer_dir(),
-- 				try_node_modules = true,
-- 			}
-- 		end

-- 		local function oxlint(extra_args)
-- 			return function()
-- 				local args = {
-- 					"--fix",
-- 					"--silent",
-- 				}

-- 				if extra_args then
-- 					vim.list_extend(args, extra_args)
-- 				end

-- 				return {
-- 					exe = "oxlint",
-- 					args = args,
-- 					stdin = false,
-- 					cwd = current_buffer_dir(),
-- 					try_node_modules = true,
-- 					ignore_exitcode = true,
-- 				}
-- 			end
-- 		end

-- 		local oxlint_fix = oxlint()
-- 		local oxlint_react = oxlint({ "--react-plugin" })
-- 		local oxlint_vue = oxlint({ "--vue-plugin" })

-- 		augroup("__formatter__", { clear = true })
-- 		autocmd("BufWritePost", {
-- 			group = "__formatter__",
-- 			command = ":FormatWrite",
-- 		})

-- 		require("formatter").setup({
-- 			logging = true,
-- 			log_level = vim.log.levels.WARN,
-- 			filetype = {
-- 				lua = {
-- 					require("formatter.filetypes.lua").stylua,
-- 				},
-- 				javascript = {
-- 					oxlint_fix,
-- 					oxfmt,
-- 				},
-- 				javascriptreact = {
-- 					oxlint_react,
-- 					oxfmt,
-- 				},
-- 				typescript = {
-- 					oxlint_fix,
-- 					oxfmt,
-- 				},
-- 				typescriptreact = {
-- 					oxlint_react,
-- 					oxfmt,
-- 				},
-- 				vue = {
-- 					oxlint_vue,
-- 					oxfmt,
-- 				},
-- 				json = {
-- 					oxfmt,
-- 				},
-- 				md = {
-- 					oxfmt,
-- 				},
-- 				markdown = {
-- 					oxfmt,
-- 				},
-- 				php = {
-- 					require("formatter.filetypes.php").pint,
-- 				},
-- 				html = {
-- 					oxfmt,
-- 				},
-- 				["*"] = {
-- 					require("formatter.filetypes.any").remove_trailing_whitespace,
-- 				},
-- 			},
-- 		})
-- 	end,
-- }

return {
	"mhartington/formatter.nvim",
	config = function()
		local util = require("formatter.util")

		local function find_project_file(names)
			return vim.fs.find(names, {
				path = util.get_current_buffer_file_dir(),
				upward = true,
			})[1]
		end

		local function project_executable(root, name)
			local executable = root .. "/vendor/bin/" .. name
			return vim.fn.executable(executable) == 1 and util.escape_path(executable) or name
		end

		local function php_cs_fixer()
			local config = find_project_file({ ".php-cs-fixer.php", ".php-cs-fixer.dist.php" })
			if not config then
				return
			end

			local root = vim.fs.dirname(config)
			return {
				exe = project_executable(root, "php-cs-fixer"),
				args = {
					"fix",
					"--config=" .. util.escape_path(config),
					"--path-mode=override",
					"--using-cache=no",
					"--sequential",
				},
				stdin = false,
				cwd = root,
			}
		end

		local function pint()
			local composer = find_project_file("composer.json")
			local root = composer and vim.fs.dirname(composer) or util.get_current_buffer_file_dir()
			return {
				exe = project_executable(root, "pint"),
				stdin = false,
				cwd = root,
				ignore_exitcode = true,
			}
		end

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
					require("formatter.filetypes.typescript").prettierd,
				},
				typescript = {
					require("formatter.filetypes.typescript").prettierd,
				},
				vue = {
					require("formatter.filetypes.typescript").prettierd,
				},
				json = {
					require("formatter.filetypes.typescript").prettierd,
				},
				md = {
					require("formatter.filetypes.typescript").prettierd,
				},
				php = {
					php_cs_fixer,
					pint,
				},
				html = {
					require("formatter.filetypes.typescript").prettierd,
				},
				["*"] = {
					require("formatter.filetypes.any").remove_trailing_whitespace,
				},
			},
		})
	end,
}
