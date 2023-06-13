if not vim.g.vscode then
	vim.opt.termguicolors = true

	if os.getenv("TERM") == "xterm-kitty" and not vim.g.neovide then
		require("material").setup({
			disable = {
				background = true,
			},
		})

		require("lualine").setup({
			options = {
				icons_enabled = true,
				theme = "onedark",
			},
		})
	end

	vim.g.material_style = "darker"
	vim.cmd("colorscheme material")

	vim.opt.guifont = { "JetBrains Mono, NotoSansMono Nerd Font", ":h10" }

	-- Configure neovide settings
	if vim.g.neovide then
		vim.g.neovide_cursor_animation_length = 0.05
		vim.g.neovide_cursor_trail_size = 0.5
		vim.g.neovide_cursor_antialiasing = true
		vim.opt.guifont = { "JetBrains Mono, NotoSansMono Nerd Font", ":h8" }
	end
end
