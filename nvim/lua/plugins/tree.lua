return {
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
				filesystem_watchers = {
					debounce_delay = 1000,
					ignore_dirs = {
						"node_modules",
					},
				},
			})
		end
	end,
}
