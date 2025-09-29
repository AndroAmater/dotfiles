return {
	"neovim/nvim-lspconfig",
	flags = {
		allow_incremental_sync = false,
		debounce_text_changes = 100,
	},
	dependencies = {
		"williamboman/mason-lspconfig.nvim",
		"j-hui/fidget.nvim",
		"rust-lang/rust.vim",
		"dmmulroy/tsc.nvim",
	},
	setup = function() end,
	config = function()
		require("fidget").setup({})

		local capabilities = require("cmp_nvim_lsp").default_capabilities()
		local vue_language_server_path = vim.fn.expand("$MASON/packages")
			.. "/vue-language-server"
			.. "/node_modules/@vue/language-server"
		local tsserver_filetypes = { "typescript", "javascript", "javascriptreact", "typescriptreact", "vue" }
		local vue_plugin = {
			name = "@vue/typescript-plugin",
			location = vue_language_server_path,
			languages = { "vue" },
			configNamespace = "typescript",
		}
		local vtsls_config = {
			settings = {
				vtsls = {
					tsserver = {
						globalPlugins = {
							vue_plugin,
						},
					},
				},
			},
			filetypes = tsserver_filetypes,
		}

		vim.lsp.config("vtsls", vtsls_config)
		vim.lsp.config("vue_ls", {})
		vim.lsp.config("ts_ls", {
			capabilities = capabilities,
			init_options = {
				plugins = {
					vue_plugin,
				},
				preferences = {
					includePackageJsonAutoImports = "on",
					maximumHoverLength = 5000,
				},
			},
			filetypes = tsserver_filetypes,
		})
		vim.lsp.enable({ "vtsls", "vue_ls" })
		vim.lsp.enable("eslint", {
			codeActionOnSave = {
				enable = true,
			},
		})

		vim.lsp.config("intelephense", {
			root_markers = { "composer.json" },
			init_options = {
				licenceKey = "002BAVBEE0B7W70",
			},
			settings = {
				intelephense = {
					files = {
						maxSize = 1000000000000,
					},
				},
			},
		})
		vim.lsp.enable("intelephense")

		vim.lsp.config("phpactor", {
			root_markers = { "composer.json" },
			init_options = {
				["language_server_phpstan.enabled"] = true,
				["language_server_phpstan.bin"] = "vendor/bin/phpstan",
				["language_server_phpstan.mem_limit"] = "8G",
				["language_server.diagnostic_providers"] = { "phpstan" },
			},
		})
		vim.lsp.enable("phpactor")

		-- vim.lsp.enable("laravel_ls")

		vim.lsp.enable("gopls", {
			settings = {
				gopls = {
					analyses = {
						unusedparams = true,
					},
					staticcheck = true,
					gofumpt = true,
				},
			},
		})
		vim.lsp.enable("pyright")

		-- Global mappings.
		-- See `:help vim.diagnostic.*` for documentation on any of the below functions
		vim.keymap.set("n", "<space>e", vim.diagnostic.open_float)
		vim.keymap.set("n", "[d", vim.diagnostic.goto_prev)
		vim.keymap.set("n", "]d", vim.diagnostic.goto_next)
		vim.keymap.set("n", "<space>q", vim.diagnostic.setloclist)

		-- Use LspAttach autocommand to only map the following keys
		-- after the language server attaches to the current buffer
		vim.api.nvim_create_autocmd("LspAttach", {
			group = vim.api.nvim_create_augroup("UserLspConfig", {}),
			callback = function(ev)
				-- Enable completion triggered by <c-x><c-o>
				vim.bo[ev.buf].omnifunc = "v:lua.vim.lsp.omnifunc"

				-- Buffer local mappings.
				-- See `:help vim.lsp.*` for documentation on any of the below functions
				local opts = { buffer = ev.buf }
				vim.keymap.set("n", "gD", vim.lsp.buf.declaration, opts)
				vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)
				vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)
				vim.keymap.set("n", "gi", vim.lsp.buf.implementation, opts)
				vim.keymap.set("n", "<C-k>", vim.lsp.buf.signature_help, opts)
				vim.keymap.set("n", "<space>wa", vim.lsp.buf.add_workspace_folder, opts)
				vim.keymap.set("n", "<space>wr", vim.lsp.buf.remove_workspace_folder, opts)
				vim.keymap.set("n", "<space>wl", function()
					print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
				end, opts)
				vim.keymap.set("n", "<space>D", vim.lsp.buf.type_definition, opts)
				vim.keymap.set("n", "<space>rn", vim.lsp.buf.rename, opts)
				vim.keymap.set({ "n", "v" }, "<space>ca", vim.lsp.buf.code_action, opts)
				vim.keymap.set("n", "gr", vim.lsp.buf.references, opts)
				vim.keymap.set("n", "<space>f", function()
					vim.lsp.buf.format({ async = true })
				end, opts)
			end,
		})

		-- go autoformat on save
		vim.api.nvim_create_autocmd("BufWritePre", {
			pattern = "*.go",
			callback = function()
				local params = vim.lsp.util.make_range_params()
				params.context = { only = { "source.organizeImports" } }
				-- buf_request_sync defaults to a 1000ms timeout. Depending on your
				-- machine and codebase, you may want longer. Add an additional
				-- argument after params if you find that you have to write the file
				-- twice for changes to be saved.
				-- E.g., vim.lsp.buf_request_sync(0, "textDocument/codeAction", params, 3000)
				local result = vim.lsp.buf_request_sync(0, "textDocument/codeAction", params)
				for cid, res in pairs(result or {}) do
					for _, r in pairs(res.result or {}) do
						if r.edit then
							local enc = (vim.lsp.get_client_by_id(cid) or {}).offset_encoding or "utf-16"
							vim.lsp.util.apply_workspace_edit(r.edit, enc)
						end
					end
				end
				vim.lsp.buf.format({ async = false })
			end,
		})
	end,
}
