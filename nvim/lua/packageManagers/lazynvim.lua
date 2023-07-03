local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
	vim.fn.system({
		"git",
		"clone",
		"--filter=blob:none",
		"https://github.com/folke/lazy.nvim.git",
		"--branch=stable", -- latest stable release
		lazypath,
	})
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
	-- Support
	{ "nvim-lua/plenary.nvim" },
	{ "rust-lang/rust.vim" },

	-- Session
	{
		"rmagatti/auto-session",
		lazy = false,
		config = function()
			require("auto-session").setup({
				log_level = "error",
				auto_session_suppress_dirs = { "~/", "~/Projects", "~/Downloads", "/", "~/Hudlajf" },
				auto_save_enabled = true,
				auto_session_enable_last_session = false,
				post_restore_cmds = {
					function()
						require("nvim-tree.api").tree.toggle({ focus = false, find_file = true })
					end,
				},
			})
		end,
	},

	-- Themes
	{
		"catppuccin/nvim",
		name = "catppuccin",
		opts = {
			flavour = "mocha",
			background = {
				light = "latta",
				dark = "mocha",
			},
			styles = {
				comments = {},
				conditionals = {},
				loops = {},
				functions = {},
				keywords = {},
				strings = {},
				variables = {},
				numbers = {},
				booleans = {},
				properties = {},
				types = {},
			},
			transparent_background = false,
		},
	},
	-- {
	-- 	"https://github.com/marko-cerovac/material.nvim.git",
	-- 	config = function()
	-- 		require("material").setup({
	-- 			plugins = {
	-- 				"gitsigns",
	-- 				"indent-blankline",
	-- 				"nvim-tree",
	-- 				"telescope",
	-- 				"trouble",
	-- 			},
	-- 		})
	-- 	end,
	-- },
	-- { 'rebelot/kanagawa.nvim' },
	-- {
	--     'kaicataldo/material.vim',
	--     config = function()
	--         vim.g.material_theme_style = 'darker'
	--     end
	-- },

	-- Decorational
	{
		"echasnovski/mini.animate",
		version = false,
		config = function()
			local animate = require("mini.animate")
			animate.setup({
				cursor = {
					enable = true,
					timing = animate.gen_timing.linear({ duration = 100, unit = "total" }),
				},
				scroll = {
					enable = false,
				},
				resize = {
					enable = false,
				},
				open = {
					enable = false,
				},
				close = {
					enable = false,
				},
			})
		end,
	},

	-- Visual plugins
	{
		"https://github.com/Yggdroot/indentLine.git",
		config = function()
			vim.g.indentLine_char = "▏"
			vim.g.vim_json_conceal = 0
			vim.g.markdown_syntax_conceal = 0
			vim.g.indentLine_setConceal = 0
		end,
	},
	{
		"nvim-lualine/lualine.nvim",
		config = function()
			-- local material = require('lualine.themes.material')
			require("lualine").setup({
				options = {
					icons_enabled = true,
					theme = "material",
					component_separators = { left = "", right = "" },
					section_separators = { left = "", right = "" },
					disabled_filetypes = {
						statusline = {},
						winbar = {},
					},
					ignore_focus = {},
					always_divide_middle = true,
					globalstatus = false,
					refresh = {
						statusline = 1000,
						tabline = 1000,
						winbar = 1000,
					},
				},
				sections = {
					lualine_a = { "mode" },
					lualine_b = { "branch", "diff", "diagnostics" },
					lualine_c = { "filename" },
					lualine_x = { "encoding", "fileformat", "filetype" },
					lualine_y = { "progress" },
					lualine_z = { "location" },
				},
				inactive_sections = {
					lualine_a = {},
					lualine_b = {},
					lualine_c = { "filename" },
					lualine_x = { "location" },
					lualine_y = {},
					lualine_z = {},
				},
				tabline = {},
				winbar = {},
				inactive_winbar = {},
				extensions = {},
			})
		end,
	},
	{
		"nvim-tree/nvim-web-devicons",
	},
	{
		"brenoprata10/nvim-highlight-colors",
		config = function()
			require("nvim-highlight-colors").setup({
				render = "background",
				enable_named_colors = true,
			})
			require("nvim-highlight-colors").turnOn()
		end,
	},
	{
		"wfxr/minimap.vim",
		config = function()
			vim.g.minimap_width = 15
			vim.g.minimap_auto_start = 1
			vim.g.minimap_auto_start_win_enter = 1
			vim.g.minimap_highlight_search = 1
			vim.g.minimap_git_colors = 1
		end,
	},
	{ "petertriho/nvim-scrollbar" },
	{ "https://github.com/airblade/vim-gitgutter.git" },
	{
		"folke/todo-comments.nvim",
		requires = "nvim-lua/plenary.nvim",
		config = function()
			require("todo-comments").setup({
				-- your configuration comes here
				-- or leave it empty to use the default settings
				-- refer to the configuration section below
			})
		end,
	},
	{
		"nvim-orgmode/orgmode",
		config = function()
			-- Load custom treesitter grammar for org filetype
			require("orgmode").setup_ts_grammar()

			-- Treesitter configuration
			require("nvim-treesitter.configs").setup({
				-- If TS highlights are not enabled at all, or disabled via `disable` prop,
				-- highlighting will fallback to default Vim syntax highlighting
				highlight = {
					enable = true,
					-- Required for spellcheck, some LaTex highlights and
					-- code block highlights that do not have ts grammar
					additional_vim_regex_highlighting = { "org" },
				},
				ensure_installed = { "org" }, -- Or run :TSUpdate org
			})

			require("orgmode").setup({})
		end,
	},

	-- Navigation
	{ "dyng/ctrlsf.vim" },
	{ "christoomey/vim-tmux-navigator" },
	{
		"nvim-pack/nvim-spectre",
		config = function()
			require("spectre").setup()
		end,
	},
	{ "ray-x/guihua.lua" },
	{
		"ray-x/sad.nvim",
		config = function()
			require("sad").setup({
				debug = false, -- print debug info
				diff = "delta", -- you can use `less`, `diff-so-fancy`
				ls_file = "fd", -- also git ls-files
				exact = false, -- exact match
				vsplit = false, -- split sad window the screen vertically, when set to number
				-- it is a threadhold when window is larger than the threshold sad will split vertically,
				height_ratio = 0.8, -- height ratio of sad window when split horizontally
				width_ratio = 0.8, -- height ratio of sad window when split vertically
			})
		end,
	},
	--{
	--	"folke/flash.nvim",
	--	event = "VeryLazy",
	--	---@type Flash.Config
	--	opts = {},
	--	keys = {
	--		{
	--			"s",
	--			mode = { "n", "o" },
	--			function()
	--				require("flash").jump()
	--			end,
	--			desc = "Flash",
	--		},
	--		{
	--			"S",
	--			mode = { "n", "o" },
	--			function()
	--				require("flash").treesitter()
	--			end,
	--			desc = "Flash Treesitter",
	--		},
	--		{
	--			"r",
	--			mode = "o",
	--			function()
	--				require("flash").remote()
	--			end,
	--			desc = "Remote Flash",
	--		},
	--		{
	--			"R",
	--			mode = { "o", "x" },
	--			function()
	--				require("flash").treesitter_search()
	--			end,
	--			desc = "Flash Treesitter Search",
	--		},
	--		{
	--			"<c-f>",
	--			mode = { "c" },
	--			function()
	--				require("flash").toggle()
	--			end,
	--			desc = "Toggle Flash Search",
	--		},
	--	},
	--},
	{
		"ThePrimeagen/harpoon",
		config = function()
			require("harpoon").setup({
				menu = {
					width = 120,
				},
			})
		end,
	},
	{ "nvim-telescope/telescope-fzf-native.nvim", build = "make" },
	{
		"nvim-telescope/telescope.nvim",
		config = function()
			local telescope = require("telescope")
			local telescopeconfig = require("telescope.config")
			local actions = require("telescope.actions")

			-- clone the default telescope configuration
			local vimgrep_arguments = { unpack(telescopeconfig.values.vimgrep_arguments) }

			-- i want to search in hidden/dot files.
			table.insert(vimgrep_arguments, "--hidden")
			-- i don't want to search in the `.git` directory.
			table.insert(vimgrep_arguments, "--glob")
			table.insert(vimgrep_arguments, "!**/.git/*")
			table.insert(vimgrep_arguments, "--glob")
			table.insert(vimgrep_arguments, "!**/vendor/*")
			table.insert(vimgrep_arguments, "--glob")
			table.insert(vimgrep_arguments, "!**/node_modules/*")

			telescope.setup({
				defaults = {
					-- `hidden = true` is not supported in text grep commands.
					vimgrep_arguments = vimgrep_arguments,
				},
				color_devicons = true,
				sorting_strategy = "ascending",
				scroll_strategy = "cycle",
				mappings = {
					i = {
						["<C-j>"] = actions.move_selection_next,
						["<C-k>"] = actions.move_selection_previous,
					},
				},
				pickers = {
					find_files = {
						find_command = {
							"rg",
							"--files",
							"--hidden",
							"--no-ignore",
							"--glob",
							"!**/.git/*",
							"-g",
							"!**/node_modules/*",
							"-g",
							"!**/vendor/*",
						},
					},
				},
				extensions = {
					fzf = {
						fuzzy = true,
						override_generic_sorter = true,
						override_file_sorter = true,
						case_mode = "smart_case",
					},
				},
			})

			telescope.load_extension("fzf")
		end,
	},
	{
		"jake-stewart/jfind.nvim",
		keys = {
			{ "<c-f>" },
		},
		config = function()
			require("jfind").setup({
				exclude = {
					".git",
					".idea",
					".vscode",
					".sass-cache",
					".class",
					"__pycache__",
					"node_modules",
					"target",
					"build",
					"tmp",
					"assets",
					"dist",
					"*.iml",
					"*.meta",
					"vendor",
				},
				border = "rounded",
				tmux = true,
				key = "<c-f>",
			})
		end,
	},
	{
		"nvim-tree/nvim-tree.lua",
		config = function()
			if not vim.g.vscode then
				-- disable netrw at the very start of your init.lua (strongly advised)
				vim.g.loaded_netrw = 1
				vim.g.loaded_netrwPlugin = 1

				-- set termguicolors to enable highlight groups
				vim.opt.termguicolors = true

				require("nvim-tree").setup({
					sort_by = "case_sensitive",
					view = {
						width = 50,
					},
					filters = {
						dotfiles = false,
					},
					update_focused_file = {
						enable = true,
					},
					git = {
						enable = true,
						ignore = false,
					},
				})

				-- Auto Open
				local function open_nvim_tree(data)
					-- buffer is a real file on the disk
					local real_file = vim.fn.filereadable(data.file) == 1

					-- -- buffer is a [No Name]
					local no_name = data.file == "" and vim.bo[data.buf].buftype == ""

					if not real_file and not no_name then
						return
					end
					-- open the tree, find the file but don't focus it
					require("nvim-tree.api").tree.toggle({ focus = false, find_file = true })
				end

				-- vim.api.nvim_create_autocmd({ "VimEnter" }, { callback = open_nvim_tree })
			end
		end,
	},
	{
		"akinsho/bufferline.nvim",
		version = "v3.*",
		dependencies = "nvim-tree/nvim-web-devicons",
		config = function()
			require("bufferline").setup({})
		end,
	},

	-- Editing
	{ "mg979/vim-visual-multi" },
	{
		"github/copilot.vim",
		config = function()
			vim.g.copilot_no_tab_map = true
			vim.api.nvim_set_keymap("i", "<C-J>", 'copilot#Accept("<CR>")', { silent = true, expr = true })
		end,
	},
	{ "https://github.com/cohama/lexima.vim.git" },
	"https://github.com/tpope/vim-commentary.git",
	"https://github.com/tpope/vim-surround.git",
	-- 'https://github.com/easymotion/vim-easymotion.git',

	-- Git/history
	{ "https://github.com/tpope/vim-fugitive.git" },
	{ "sindrets/diffview.nvim" },
	{
		"https://github.com/mbbill/undotree.git",
		config = function()
			vim.g.undotree_WindowLayout = 2
			vim.g.undotree_SplitWidth = 20
		end,
	},
	{ "https://github.com/rbong/vim-flog.git" },
	{ "aspeddro/gitui.nvim" },
	{
		"gbprod/yanky.nvim",
		config = function()
			require("yanky").setup({
				ring = {
					history_length = 10000,
					storage = "shada",
					sync_with_numbered_registers = true,
					cancel_event = "update",
				},
				picker = {
					select = {
						action = nil,
					},
					telescope = {
						use_default_mappings = true,
						mappings = nil,
					},
				},
				system_clipboard = {
					sync_with_ring = true,
				},
				highlight = {
					on_put = false,
					on_yank = false,
				},
				preserve_cursor_position = {
					enabled = true,
				},
			})
			require("telescope").load_extension("yank_history")
		end,
	},

	-- Terminal
	{
		"akinsho/toggleterm.nvim",
		config = function()
			require("toggleterm").setup({
				size = function(term)
					if term.direction == "horizontal" then
						return 25
					elseif term.direction == "vertical" then
						return vim.o.columns * 0.4
					end
				end,
				open_mapping = [[<c-p>]],
				start_in_insert = false,
			})
		end,
	},

	-- Diagnostics
	{ "folke/trouble.nvim", lazy = false },

	-- LSP
	{
		"nvim-treesitter/nvim-treesitter",
		lazy = false,
		config = function()
			require("nvim-treesitter.configs").setup({
				-- A list of parser names, or "all" (the four listed parsers should always be installed)
				ensure_installed = {
					"c",
					"lua",
					"vim",
					"help",
					"typescript",
					"javascript",
					"php",
					"rust",
					"gitignore",
					"json",
					"bash",
					"comment",
					"css",
					"dockerfile",
					"git_rebase",
					"gitattributes",
					"gitcommit",
					"go",
					"graphql",
					"html",
					"ini",
					"jsdoc",
					"json5",
					"make",
					"markdown",
					"phpdoc",
					"regex",
					"rust",
					"scss",
					"sql",
					"vue",
					"yaml",
				},
				-- Install parsers synchronously (only applied to `ensure_installed`)
				sync_install = false,

				-- Automatically install missing parsers when entering buffer
				-- Recommendation: set to false if you don't have `tree-sitter` CLI installed locally
				auto_install = true,

				highlight = {
					enable = true,
				},
			})
		end,
	},
	{
		"VonHeikemen/lsp-zero.nvim",
		branch = "v1.x",
		dependencies = {
			-- LSP Support
			{ "neovim/nvim-lspconfig" }, -- Required
			{ "williamboman/mason.nvim" }, -- Optional
			{ "williamboman/mason-lspconfig.nvim" }, -- Optional

			-- Autocompletion
			{ "hrsh7th/nvim-cmp" }, -- Required
			{ "hrsh7th/cmp-nvim-lsp" }, -- Required
			{ "hrsh7th/cmp-buffer" }, -- Optional
			{ "hrsh7th/cmp-path" }, -- Optional
			{ "saadparwaiz1/cmp_luasnip" }, -- Optional
			{ "hrsh7th/cmp-nvim-lua" }, -- Optional

			-- Formating
			{ "https://github.com/jose-elias-alvarez/null-ls.nvim.git" },

			-- Snippets
			{ "L3MON4D3/LuaSnip" }, -- Required
			{ "rafamadriz/friendly-snippets" }, -- Optional
		},
		config = function()
			require("cmp").setup({
				sources = {
					{ name = "orgmode" },
				},
			})

			-- LSP
			local lsp = require("lsp-zero").preset({
				name = "minimal",
				set_lsp_keymaps = true,
				manage_nvim_cmp = true,
				suggest_lsp_servers = false,
			})

			-- (Optional) Configure lua language server for neovim
			lsp.nvim_workspace()

			lsp.setup()

			lsp.format_on_save({
				format_opts = {
					async = true,
					timeout_ms = 10000,
				},
				servers = {
					["null-ls"] = {
						"lua",
						"javascript",
						"typescript",
						"vue",
						"css",
						"json",
						"html",
						"markdown",
						"yaml",
						"php",
					},
				},
			})

			local null_ls = require("null-ls")
			local prettierdphp = require("packageManagers.utils.prettierdphp")

			null_ls.setup({
				sources = {
					prettierdphp,
					null_ls.builtins.formatting.stylua,
					null_ls.builtins.formatting.prettierd,
				},
			})
		end,
	},
})
