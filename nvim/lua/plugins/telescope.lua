return {
	"nvim-telescope/telescope.nvim",
	config = function()
		local telescope = require("telescope")
		local actions = require("telescope.actions")

		telescope.setup({
			defaults = {
				path_display = {
					truncate = true,
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
					-- "--smart-case",
					"--hidden",
					-- "--no-ignore",
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
						"--glob",
						"!**/.git/*",
						"-g",
						"!**/node_modules/*",
						"-g",
						"!**/vendor/*",
					},
				},
				live_grep = {
					glob_pattern = {
						"!**/.git/*",
						"!**/node_modules/*",
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
}
