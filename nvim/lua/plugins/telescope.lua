return {
	"nvim-telescope/telescope.nvim",
	dependencies = {
		{ "nvim-telescope/telescope-fzf-native.nvim", build = "make" },
	},
	config = function()
		local telescope = require("telescope")
		local actions = require("telescope.actions")

		telescope.setup({
			defaults = {
				preview = {
					filesize_limit = 0.1,
				},
				path_display = {
					"truncate",
				},
				wrap_results = true,
				layout_config = {
					prompt_position = "bottom",
				},
				vimgrep_arguments = {
					"rg",
					"--color=never",
					"--no-heading",
					"--with-filename",
					"--line-number",
					"--column",
					"--smart-case",
					"--hidden",
					"--no-ignore",
					"--sort",
					"path",
				},
				color_devicons = true,
				sorting_strategy = "descending",
				scroll_strategy = "cycle",
				mappings = {
					i = {
						["<C-j>"] = actions.move_selection_next,
						["<C-k>"] = actions.move_selection_previous,
					},
				},
			},
			pickers = {
				find_files = {
					find_command = {
						"rg",
						"--files",
						"--hidden",
						"--no-ignore",
						"--sort",
						"path",
						"-g",
						"!.angular",
						"-g",
						"!dist",
						"-g",
						"!node_modules",
						"-g",
						"!vendor",
						"-g",
						"!coverage",
						"-g",
						"!.git",
						"-g",
						"!.venv",
						"-g",
						"!.vitepress",
					},
				},
				live_grep = {
					glob_pattern = {
						"!**/.git/*",
						"!**/.angular/*",
						"!**/.nx/*",
						"!**/node_modules/*",
						"!**/vendor/*",
						"!**/dist/*",
						"!**/generator/generated/*",
						"!**/.venv/*",
						"!**/.vitepress/*",
						"!**/laravel.log",
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
}
