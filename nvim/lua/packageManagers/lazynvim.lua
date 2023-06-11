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

    -- Session
    { 'https://github.com/tpope/vim-obsession.git' },

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
            vim.g.vim_json_conceal = 0
            vim.g.markdown_syntax_conceal = 0
            vim.g.indentLine_setConceal=0
        end
    },
    {
        'nvim-lualine/lualine.nvim',
        config = function()
            -- local material = require('lualine.themes.material')
            require('lualine').setup {
                options = {
                    icons_enabled = true,
                    theme = "material",
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
    {
        'nvim-tree/nvim-web-devicons',
    },
    {
        'brenoprata10/nvim-highlight-colors',
        config = function()
            require("nvim-highlight-colors").setup{
                render = 'background',
                enable_named_colors = true
            }
            require("nvim-highlight-colors").turnOn()
        end
    },
    {
        "wfxr/minimap.vim",
        config = function ()
            vim.g.minimap_width = 15
            vim.g.minimap_auto_start = 1
            vim.g.minimap_auto_start_win_enter = 1
            vim.g.minimap_highlight_search = 1
            vim.g.minimap_git_colors = 1
        end
    },
    { "petertriho/nvim-scrollbar" },
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

    -- Navigation
    {
        'https://github.com/ggandor/leap.nvim.git',
        config = function ()
            require('leap').add_default_mappings()
        end
    },
    {
        'ThePrimeagen/harpoon',
        config = function ()
            require("harpoon").setup({
                menu = {
                    width = 120,
                }
            })
        end
    },
    { 'nvim-telescope/telescope-fzf-native.nvim', build = 'make' },
    {
        'nvim-telescope/telescope.nvim',
        config = function ()
            local telescope = require("telescope")
            local telescopeconfig = require("telescope.config")
            local actions = require("telescope.actions")

            -- clone the default telescope configuration
            local vimgrep_arguments = { unpack(telescopeconfig.values.vimgrep_arguments) }

            -- i want to search in hidden/dot files.
            table.insert(vimgrep_arguments, "--hidden")
            -- i don't want to search in the `.git` directory.
            table.insert(vimgrep_arguments, "--glob")
            table.insert(vimgrep_arguments, "!**/.git/*")
            table.insert(vimgrep_arguments, "--glob")
            table.insert(vimgrep_arguments, "!**/vendor/*")
            table.insert(vimgrep_arguments, "--glob")
            table.insert(vimgrep_arguments, "!**/node_modules/*")

            telescope.setup({
                defaults = {
                    -- `hidden = true` is not supported in text grep commands.
                    vimgrep_arguments = vimgrep_arguments,
                },
                color_devicons = true,
                sorting_strategy = "ascending",
                scroll_strategy = "cycle",
                mappings = {
                    i = {
                        ["<C-j>"] = actions.move_selection_next,
                        ["<C-k>"] = actions.move_selection_previous,
                    }
                },
                pickers = {
                    find_files = {
                        find_command = { "rg", "--files", "--hidden", "--no-ignore", "--glob", "!**/.git/*", "-g", "!**/node_modules/*", "-g", "!**/vendor/*" },
                    },
                },
                extensions = {
                    fzf = {
                        fuzzy = true,
                        override_generic_sorter = true,
                        override_file_sorter = true,
                        case_mode = "smart_case"
                    }
                }
            })

            telescope.load_extension("fzf")
        end
    },
     {
            "jake-stewart/jfind.nvim",
            keys = {
                {"<c-f>"},
            },
            config = function()
                require("jfind").setup({
                    exclude = {
                        ".git",
                        ".idea",
                        ".vscode",
                        ".sass-cache",
                        ".class",
                        "__pycache__",
                        "node_modules",
                        "target",
                        "build",
                        "tmp",
                        "assets",
                        "dist",
                        "*.iml",
                        "*.meta",
                        "vendor"
                    },
                    border = "rounded",
                    tmux = true,
                    key = "<c-f>"
                });
            end
        },
        {
        'nvim-tree/nvim-tree.lua',
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
                        mappings = {
                            list = {
                                { key = "u", action = "dir_up" },
                            },
                        },
                    },
                })

                -- Auto Open
                local function open_nvim_tree(data)
                    -- buffer is a real file on the disk
                    local real_file = vim.fn.filereadable(data.file) == 1

                    -- buffer is a [No Name]
                    local no_name = data.file == "" and vim.bo[data.buf].buftype == ""

                    if not real_file and not no_name then
                        return
                    end
                    -- open the tree, find the file but don't focus it
                    require("nvim-tree.api").tree.toggle({ focus = false, find_file = true, })
                end

                vim.api.nvim_create_autocmd({ "VimEnter" }, { callback = open_nvim_tree })
            end
        end
    },
    {
        'akinsho/bufferline.nvim',
        version = "v3.*",
        dependencies = 'nvim-tree/nvim-web-devicons',
        config = function ()
            require("bufferline").setup{}
        end
    },

    -- Editing
    { 'mg979/vim-visual-multi' },
    {
        "github/copilot.vim",
        config = function()
            vim.g.copilot_no_tab_map = true
            vim.api.nvim_set_keymap("i", "<C-J>", 'copilot#Accept("<CR>")', { silent = true, expr = true })
        end
    },
    { "https://github.com/cohama/lexima.vim.git" },
    'https://github.com/tpope/vim-commentary.git',
    'https://github.com/tpope/vim-surround.git',
    -- 'https://github.com/easymotion/vim-easymotion.git',

    -- Git/history
    { 'https://github.com/tpope/vim-fugitive.git' },
    { 'sindrets/diffview.nvim' },
    {
        "https://github.com/mbbill/undotree.git",
        config = function()
            vim.g.undotree_WindowLayout = 2
            vim.g.undotree_SplitWidth = 20
        end
    },
    { "https://github.com/rbong/vim-flog.git" },
    { "aspeddro/gitui.nvim" },

    -- Terminal
    {
        'akinsho/toggleterm.nvim',
        config = function ()
            require("toggleterm").setup{
                size = function(term)
                    if term.direction == "horizontal" then
                        return 25
                    elseif term.direction == "vertical" then
                        return vim.o.columns * 0.4
                    end
                end,
                open_mapping = [[<c-p>]],
                start_in_insert = false
            }
        end
    },

    -- Diagnostics
    { 'folke/trouble.nvim', lazy=false },

    -- Formating
    {
        'sbdchd/neoformat',
        config = function()
            vim.g.neoformat_try_node_exe = 1
            vim.cmd("autocmd BufWritePre *.vue,*.js,*.jsx,*.cjs,*.mjs,*.ts,*.tsx,*.cts,*.mts Neoformat")
        end
    },

    -- LSP
    {
        'nvim-treesitter/nvim-treesitter', lazy = false,
        config = function()
            require'nvim-treesitter.configs'.setup {
                -- A list of parser names, or "all" (the four listed parsers should always be installed)
                ensure_installed = { 
                    "c",
                    "lua",
                    "vim",
                    "help",
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
                    "yaml"
                },
                -- Install parsers synchronously (only applied to `ensure_installed`)
                sync_install = false,

                -- Automatically install missing parsers when entering buffer
                -- Recommendation: set to false if you don't have `tree-sitter` CLI installed locally
                auto_install = true,

                highlight = {
                    enable = true,
                }
            }
        end
    },
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
        },
        config = function ()
            -- LSP
            local lsp = require('lsp-zero').preset({
                name = 'minimal',
                set_lsp_keymaps = true,
                manage_nvim_cmp = true,
                suggest_lsp_servers = false,
            })

            -- (Optional) Configure lua language server for neovim
            lsp.nvim_workspace()

            lsp.setup()
        end
    }
})

