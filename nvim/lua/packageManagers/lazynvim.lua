local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
    vim.fn.system({
        "git",
        "clone",
        "--filter=blob:none",
        "https://github.com/folke/lazy.nvim.git",
        "--branch=stable", -- latest stable release
        lazypath,
    })
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
    -- Support
    { 'nvim-lua/plenary.nvim' },
    { 'rust-lang/rust.vim' },

    -- Themes
    -- { 'catppuccin/nvim' },
    {
        'https://github.com/marko-cerovac/material.nvim.git',
        config = function()
            require('material').setup({
                plugins = {
                    "gitsigns",
                    "indent-blankline",
                    "nvim-tree",
                    "telescope",
                    "trouble"
                }
            })
        end
    },
    -- { 'rebelot/kanagawa.nvim' },
    -- {
    --     'kaicataldo/material.vim',
    --     config = function()
    --         vim.g.material_theme_style = 'darker'
    --     end
    -- },

    -- Visual plugins
    {
        'https://github.com/Yggdroot/indentLine.git',
        config = function()
            vim.g.indentLine_char = '▏'
        end
    },
    {
        'nvim-lualine/lualine.nvim',
        config = function()
            local material = require('lualine.themes.material')
            require('lualine').setup {
                options = {
                    icons_enabled = true,
                    theme = material,
                    component_separators = { left = '', right = ''},
                    section_separators = { left = '', right = ''},
                    disabled_filetypes = {
                        statusline = {},
                        winbar = {},
                    },
                    ignore_focus = {},
                    always_divide_middle = true,
                    globalstatus = false,
                    refresh = {
                        statusline = 1000,
                        tabline = 1000,
                        winbar = 1000,
                    }
                },
                sections = {
                    lualine_a = {'mode'},
                    lualine_b = {'branch', 'diff', 'diagnostics'},
                    lualine_c = {'filename'},
                    lualine_x = {'encoding', 'fileformat', 'filetype'},
                    lualine_y = {'progress'},
                    lualine_z = {'location'}
                },
                inactive_sections = {
                    lualine_a = {},
                    lualine_b = {},
                    lualine_c = {'filename'},
                    lualine_x = {'location'},
                    lualine_y = {},
                    lualine_z = {}
                },
                tabline = {},
                winbar = {},
                inactive_winbar = {},
                extensions = {}
            }
        end
    },
    { 'nvim-tree/nvim-web-devicons' },
    { 'brenoprata10/nvim-highlight-colors' },
    { "wfxr/minimap.vim" },
    { "petertriho/nvim-scrollbar" },
    -- { 
    --     "rcarriga/nvim-notify",
    --     config = function() 
    --         vim.notify = require("notify")
    --     end
    -- },
    { "https://github.com/airblade/vim-gitgutter.git" },
    {
        "folke/todo-comments.nvim",
        requires = "nvim-lua/plenary.nvim",
        config = function()
            require("todo-comments").setup {
                -- your configuration comes here
                -- or leave it empty to use the default settings
                -- refer to the configuration section below
            }
        end
    },
    -- { 'brooth/far.vim' },

    -- Navigation
    {
        'nvim-telescope/telescope.nvim',
        config = function ()
            local telescope = require("telescope")
            local telescopeconfig = require("telescope.config")

            -- clone the default telescope configuration
            local vimgrep_arguments = { unpack(telescopeconfig.values.vimgrep_arguments) }

            -- i want to search in hidden/dot files.
            table.insert(vimgrep_arguments, "--hidden")
            -- i don't want to search in the `.git` directory.
            table.insert(vimgrep_arguments, "--glob")
            table.insert(vimgrep_arguments, "!**/.git/*")

            telescope.setup({
                defaults = {
                    -- `hidden = true` is not supported in text grep commands.
                    vimgrep_arguments = vimgrep_arguments,
                },
                pickers = {
                    find_files = {
                        find_command = { "rg", "--files", "--hidden", "--no-ignore", "--glob", "!**/.git/*", "-g", "!**/node_modules/*", "-g", "!**/vendor/*" },
                    },
                },
            })
        end
    },
    { 'nvim-tree/nvim-tree.lua' },
    { 'akinsho/bufferline.nvim' },
    -- {
    --     'glepnir/dashboard-nvim',
    --     event = 'vimenter',
    --     config = function()
    --         require('dashboard').setup {
    --             -- config
    --         }
    --     end,
    --     dependencies = { {'nvim-tree/nvim-web-devicons'}}
    -- },

    -- Editing
    { 'mg979/vim-visual-multi' },
    { "github/copilot.vim" },
    { "https://github.com/cohama/lexima.vim.git" },
    'https://github.com/tpope/vim-commentary.git',
    'https://github.com/tpope/vim-surround.git',
    -- 'https://github.com/easymotion/vim-easymotion.git',

    -- Git/history
    { 'https://github.com/tpope/vim-fugitive.git' },
    { 'sindrets/diffview.nvim' },
    { "https://github.com/mbbill/undotree.git" },
    { "https://github.com/rbong/vim-flog.git" },
    { "aspeddro/gitui.nvim" },

    -- Terminal
    { 'akinsho/toggleterm.nvim' },

    -- Diagnostics
    { 'folke/trouble.nvim', lazy=false },

    -- LSP
    { 'nvim-treesitter/nvim-treesitter', lazy = false },
    {
        'VonHeikemen/lsp-zero.nvim',
        branch = 'v1.x',
        dependencies = {
            -- LSP Support
            {'neovim/nvim-lspconfig'},             -- Required
            {'williamboman/mason.nvim'},           -- Optional
            {'williamboman/mason-lspconfig.nvim'}, -- Optional

            -- Autocompletion
            {'hrsh7th/nvim-cmp'},         -- Required
            {'hrsh7th/cmp-nvim-lsp'},     -- Required
            {'hrsh7th/cmp-buffer'},       -- Optional
            {'hrsh7th/cmp-path'},         -- Optional
            {'saadparwaiz1/cmp_luasnip'}, -- Optional
            {'hrsh7th/cmp-nvim-lua'},     -- Optional

            -- Snippets
            {'L3MON4D3/LuaSnip'},             -- Required
            {'rafamadriz/friendly-snippets'}, -- Optional
        }
    },
})

