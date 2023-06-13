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
