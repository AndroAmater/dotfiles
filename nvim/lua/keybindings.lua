-- Set the leader key
vim.g.mapleader = " "

-- Set the insert line in normal model remap
vim.keymap.set("n", "<leader>o", "o<Esc>")
vim.keymap.set("n", "<leader>O", "O<Esc>")

-- Set highlight search
vim.cmd('set hlsearch')

-- Set block cursor
vim.cmd('set guicursor=i:block')

-- Set clipboard copy commands keymaps
vim.keymap.set("n", "<leader>d", '"_d')
vim.keymap.set("n", "<leader>dd", '"_d')
vim.keymap.set("v", "<leader>d", '"_d')
vim.keymap.set("n", "<leader>x", '"_x')

vim.keymap.set("x", "<leader>p", "\"_dP")

vim.keymap.set("v", "<leader>y", '"+y')

vim.keymap.set("n", "<leader><C-v>", '"+p')
vim.keymap.set("v", "<leader><C-v>",'"+p')

-- Newline without leaving normal mode
vim.keymap.set("n", "<leader><enter>", 'i<enter><esc>')
vim.keymap.set("n", "<leader><leader><enter>", 'xi<enter><esc>')

-- Set window to middle of the screen when navigating half page up/down
if not vim.g.vscode then
	vim.keymap.set("n", "<C-d>", "<C-d>zz")
	vim.keymap.set("n", "<C-u>", "<C-u>zz")
end

-- Set ctrl+s for save
vim.keymap.set("i", "<C-s>", "<esc>:w<cr>")
vim.keymap.set("n", "<C-s>", ":w<cr>")
vim.keymap.set("v", "<C-s>", ":w<cr>")

-- Set ctrl+w for close tab
vim.keymap.set("n", "<C-w><C-w>", ":bd<cr>:bp<cr>")

-- Copilot
-- vim.g.copilot_no_tab_map = true
-- vim.api.nvim_set_keymap("i", "<C-J>", 'copilot#Accept("<CR>")', { silent = true, expr = true })

-- Window management
vim.keymap.set("n", "<C-l>", "<C-W>l")
vim.keymap.set("n", "<C-h>", "<C-W>h")
vim.keymap.set("n", "<C-k>", "<C-W>k")
vim.keymap.set("n", "<C-j>", "<C-W>j")

vim.keymap.set("n", "<C-Right>", ":vsp<cr>")
vim.keymap.set("n", "<C-Down>", ":sp<cr>")

vim.keymap.set("n", "<A-k>", ":resize -2<cr>")
vim.keymap.set("n", "<A-j>", ":resize +2<cr>")
vim.keymap.set("n", "<A-h>", ":vertical resize -2<cr>")
vim.keymap.set("n", "<A-l>", ":vertical resize +2<cr>")

vim.keymap.set("n", "<leader>=", ":vertical resize 50<cr>")

-- Set ctrl+q for quit
vim.keymap.set("n", "<C-q><C-q>", ":qa<cr>")

-- Move lines
vim.keymap.set("v", "J", ":m '>+1<CR>gv=gv")
vim.keymap.set("v", "K", ":m '<-2<CR>gv=gv")

-- Better search
vim.keymap.set("n", "<leader>ss", ":nohl<cr>")
vim.keymap.set("n", "n", "nzzzv")
vim.keymap.set("n", "N", "Nzzzv")
vim.keymap.set("n", "<leader>s", ":%s/\\<<C-r><C-w>\\>/<C-r><C-w>/gI<Left><Left><Left>")

-- Telescope
local builtin = require('telescope.builtin')
vim.keymap.set('n', '<leader>fa', builtin.find_files, {})
vim.keymap.set('n', '<leader>fg', builtin.live_grep, {})
vim.keymap.set('n', '<leader>ff', builtin.find_files, {})
vim.keymap.set('n', '<leader>fh', builtin.help_tags, {})
vim.keymap.set('n', '<leader>fd', builtin.diagnostics, {})
vim.keymap.set('n', '<leader>fc', ':TodoTelescope<cr>', {})
vim.keymap.set("n", "<C-t>", builtin.buffers, {})

-- Tabs
vim.keymap.set("n", "<C-Tab>", ":bn<cr>")

-- Git
vim.keymap.set("n", "<leader>gs", ":DiffviewOpen<cr>")
vim.keymap.set("n", "<leader>gq", ":DiffviewClose<cr>")
vim.keymap.set("n", "<leader>gc", ":Git commit<cr>")
vim.keymap.set("n", "<leader>gp", ":Git push<cr>")
vim.keymap.set("n", "<leader>gb", ":Git blame<cr>")
vim.keymap.set("n", "<leader>gl", ":Git log<cr>")
vim.keymap.set("n", "<leader>gt", ":Flog<cr>")

-- Minimap
vim.keymap.set("n", "<leader>mm", ":MinimapToggle<cr>")

-- NvimTree
vim.keymap.set('n', '<leader>tf', ':NvimTreeFocus<CR>')
vim.keymap.set('n', '<leader>tc', ':NvimTreeClose<CR>')
vim.keymap.set('n', '<leader>to', ':NvimTreeOpen<CR>')
vim.keymap.set('n', '<leader>tt', ':NvimTreeFindFile<CR>')

-- UndoTree
vim.keymap.set('n', '<leader>tu', ':UndotreeToggle<CR>')

-- Set indent level
vim.keymap.set('n', '<leader>2', ':set shiftwidth=2 tabstop=2<CR>')
vim.keymap.set('n', '<leader>4', ':set shiftwidth=4 tabstop=4<CR>')

-- Diagnostics
vim.keymap.set('n', '<leader><leader>dt', ':TroubleToggle<CR>')
vim.keymap.set('n', '<leader><leader>dc', ':TodoTrouble<CR>')

-- Search all
vim.keymap.set('n', '<leader><leader>ff', ':Farr<Cr>')
vim.keymap.set('n', '<leader><leader>fu', ':Farundo<Cr>')

-- Code actions
vim.keymap.set('n', '<leader>a', ':lua vim.lsp.buf.code_action()<CR>')
