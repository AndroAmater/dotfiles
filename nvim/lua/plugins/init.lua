return {
	-- Support
	{ "nvim-lua/plenary.nvim" },
	{ "rust-lang/rust.vim" },

	-- Visual plugins
	{ "nvim-tree/nvim-web-devicons" },
	{ "https://github.com/airblade/vim-gitgutter.git" },

	-- Navigation
	{ "christoomey/vim-tmux-navigator" },
	{ "nvim-telescope/telescope-fzf-native.nvim", build = "make" },

	-- Editing
	{ "mg979/vim-visual-multi" },
	{ "https://github.com/tpope/vim-commentary.git" },
	{ "https://github.com/tpope/vim-surround.git" },

	-- Git/history
	{ "https://github.com/rbong/vim-flog.git" },

	-- LSP
	{ "nvim-treesitter/playground" },
	{ "nvim-treesitter/nvim-treesitter-angular" },
	{ "williamboman/mason-lspconfig.nvim" }, -- Optional
	{ "j-hui/fidget.nvim" },

	-- Autocompletion
	{ "hrsh7th/cmp-nvim-lsp" },
	{ "hrsh7th/cmp-buffer" },
	{ "hrsh7th/cmp-path" },
	{ "saadparwaiz1/cmp_luasnip" },
	{ "hrsh7th/cmp-nvim-lua" },

	-- Snippets
	{ "L3MON4D3/LuaSnip" },
	{ "rafamadriz/friendly-snippets" },

	-- Angular
	{ "joeveiga/ng.nvim" },
}
