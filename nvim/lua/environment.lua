local function str_split(inputstr, sep)
	if sep == nil then
		sep = "%s"
	end
	local t = {}
	for str in string.gmatch(inputstr, "([^" .. sep .. "]+)") do
		table.insert(t, str)
	end
	return t
end

-- Set relative line number
vim.opt.rnu = true
vim.opt.nu = true

-- Neovim Vscode UI Color extension config
-- if vim.g.vscode then
-- 	vim.cmd("source ./packages/vscodeui.vim")
-- end

-- Set tab size to 4
vim.opt.tabstop = 4
vim.opt.shiftwidth = 4
vim.opt.expandtab = true

-- Show invisible characters
vim.opt.list = true
vim.opt.listchars = { space = "⋅", eol = "↴", tab = "> " }

-- Set udpatetime
vim.opt.updatetime = 50

-- Set autoindent
vim.opt.autoindent = true
vim.opt.smartindent = true

-- Set sorting defaults
vim.opt.ignorecase = true
vim.opt.smartcase = true

-- Set rulers
vim.opt.colorcolumn = "80,120,160"

-- Set title
vim.opt.title = true
vim.opt.titlestring = str_split(vim.fn.getcwd(), "/")[#str_split(vim.fn.getcwd(), "/")]

-- Set virtualtext
vim.lsp.handlers["textDocument/publishDiagnostics"] = vim.lsp.with(vim.lsp.diagnostic.on_publish_diagnostics, {
	virtual_text = true,
	signs = true,
	update_in_insert = true,
	underline = true,
})

-- Rust fmt config
vim.g.rustfmt_autosave = 1

-- Set signcolumn to always be visible
vim.opt.signcolumn = "yes"

-- Eslint auto fix on save
vim.api.nvim_create_autocmd("BufWritePre", {
	pattern = { "*.tsx", "*.ts", "*.jsx", "*.js", "*.vue" },
	command = "silent! EslintFixAll",
	group = vim.api.nvim_create_augroup("MyAutocmdsJavaScripFormatting", {}),
})

-- Configure neovide settings
vim.g.neovide_cursor_animation_length = 0.05
vim.g.neovide_cursor_trail_size = 0.5
vim.g.neovide_cursor_antialiasing = true

-- Configure undo file (persistent undo)
vim.opt.undodir = vim.fn.expand("$HOME/.config/nvim/.undodir")
vim.opt.undofile = true
