vim.g.copilot_no_tab_map = true
vim.api.nvim_set_keymap("i", "<C-J>", 'copilot#Accept("<CR>")', { silent = true, expr = true })

-- Package manager init
require("packageManagers")

-- Keybindings config
require("keybindings")

-- Editor config
require("environment")

-- Theme config
require("theme")

-- Package configs
require("packages")

vim.g.copilot_no_tab_map = true
vim.api.nvim_set_keymap("i", "<C-J>", 'copilot#Accept("<CR>")', { silent = true, expr = true })
vim.g.neovide_cursor_animation_length = 0.05
vim.g.neovide_cursor_trail_size = 0.5
vim.g.neovide_cursor_antialiasing = true
