if not vim.g.vscode then
    vim.opt.termguicolors = true

    if os.getenv("TERM") == "xterm-kitty" and not vim.g.neovide then
        require("material").setup({
            disable = {
                background = true
            },
            lualine_style = 'stealth'
        })
    end

    vim.g.material_style = "darker"
    vim.cmd("colorscheme material")

    vim.opt.guifont = { 'JetBrains Mono, NotoSansMono Nerd Font', ':h10' }
end
