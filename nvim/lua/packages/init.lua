-- Bufferline
vim.opt.termguicolors = true
require("bufferline").setup{}


-- Scrollbar
require("scrollbar").setup({

})


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


-- ToggleTerm
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


-- Minimap
vim.g.minimap_width = 15
vim.g.minimap_auto_start = 1
vim.g.minimap_auto_start_win_enter = 1
vim.g.minimap_highlight_search = 1
vim.g.minimap_git_colors = 1


-- Nvim tree
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

    -- Auto Close
    -- vim.api.nvim_create_autocmd("BufEnter", {
    --     nested = true,
    --     callback = function()
    --         if #vim.api.nvim_list_wins() == 1 and require("nvim-tree.utils").is_nvim_tree_buf() then
    --             vim.cmd "quit"
    --         end
    --     end
    -- })
end


-- Treesitter
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


-- Nvim Highlight Colors
require("nvim-highlight-colors").setup{
    render = 'background',
    enable_named_colors = true
}

require("nvim-highlight-colors").turnOn()


-- Lualine
require('lualine').setup {
  options = {
    icons_enabled = true,
    theme = 'auto',
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


-- Trouble
require("trouble").setup {}


-- Undo Tree
vim.g.undotree_WindowLayout = 2
vim.g.undotree_SplitWidth = 20
