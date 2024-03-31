return {
	"williamboman/mason.nvim",
	config = function()
		require("mason").setup({
			ensure_installed = {
				"codelldb",
				"docker-compose-language-service",
				"dockerfile-language-server",
				"eslint-lsp",
				"eslint_d",
				"gitlint",
				"gitui",
				"goimports-reviser",
				"gopls",
				"gofumpt",
				"golines",
				"html-lsp",
				"intelephense",
				"js-debug-adapter",
				"json-lsp",
				"json-to-struct",
				"jsonlint",
				"lua-language-server",
				"nginx-language-server",
				"node-debug2-adapter",
				"php-cs-fixer",
				"php-debug-adapter",
				"phpactor",
				"phpcbf",
				"phpcs",
				"phpmd",
				"phpstan",
				"prettierd",
				"rust-analyzer",
				"rustfmt",
				"sql-formatter",
				"stylua",
				"twigcs",
				"typescript-language-server",
				"vue-language-server",
				"yaml-language-server",
				"angular-language-server",
			},
		})
	end,
	build = ":MasonUpdate",
}
