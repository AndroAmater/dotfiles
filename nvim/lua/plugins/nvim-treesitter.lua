return {
	"nvim-treesitter/nvim-treesitter",
	lazy = false,
	config = function()
		require("nvim-treesitter.configs").setup({
			-- A list of parser names, or "all" (the four listed parsers should always be installed)
			ensure_installed = {
				"c",
				"lua",
				"vim",
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
			incremental_selection = {
				enable = true,
				keymaps = {
					init_selection = "<CR>",
					scope_incremental = "<CR>",
					node_incremental = "<TAB>",
					node_decremental = "<S-TAB>",
				},
			},
		})
	end,
	build = ":TSUpdate",
}
