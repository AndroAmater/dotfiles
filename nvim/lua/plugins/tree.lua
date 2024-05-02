return {
	"nvim-tree/nvim-tree.lua",
	config = function()
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
			filesystem_watchers = {
				debounce_delay = 1000,
				ignore_dirs = {
					"node_modules",
				},
			},
		})

		vim.api.nvim_create_autocmd({ "BufEnter" }, {
			pattern = "NvimTree*",
			callback = function()
				local api = require("nvim-tree.api")
				local view = require("nvim-tree.view")

				if not view.is_visible() then
					api.tree.open()
				end
			end,
		})

		require("nvim-tree.api").tree.open()
	end,
}
