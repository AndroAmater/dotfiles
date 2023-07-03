-- Set the leader key
vim.g.mapleader = " "

-- Set the insert line in normal model remap
vim.keymap.set("n", "<leader>o", "o<Esc>", { silent = true })
vim.keymap.set("n", "<leader>O", "O<Esc>", { silent = true })

-- Set highlight search
vim.cmd("set hlsearch")

-- Set block cursor
-- vim.cmd("set guicursor=i:block")

-- Set clipboard copy commands keymaps
vim.keymap.set("n", "<leader>d", '"_d', { silent = true })
vim.keymap.set("n", "<leader>dd", '"_d', { silent = true })
vim.keymap.set("v", "<leader>d", '"_d', { silent = true })
vim.keymap.set("n", "<leader>x", '"_x', { silent = true })

vim.keymap.set("x", "<leader>p", '"_dP', { silent = true })
vim.keymap.set("v", "<leader>y", '"+y', { silent = true })

vim.keymap.set("n", "<leader><C-v>", '"+p', { silent = true })
vim.keymap.set("v", "<leader><C-v>", '"+p', { silent = true })

vim.keymap.set({ "n", "x" }, "p", "<Plug>(YankyPutAfter)")
vim.keymap.set({ "n", "x" }, "P", "<Plug>(YankyPutBefore)")
vim.keymap.set({ "n", "x" }, "gp", "<Plug>(YankyGPutAfter)")
vim.keymap.set({ "n", "x" }, "gP", "<Plug>(YankyGPutBefore)")
vim.keymap.set({ "n", "x" }, "y", "<Plug>(YankyYank)")

-- Newline without leaving normal mode
vim.keymap.set("n", "<leader><enter>", "i<enter><esc>", { silent = true })
vim.keymap.set("n", "<leader><leader><enter>", "xi<enter><esc>", { silent = true })

-- Set window to middle of the screen when navigating half page up/down
if not vim.g.vscode then
	vim.keymap.set("n", "<C-d>", "<C-d>zz")
	vim.keymap.set("n", "<C-u>", "<C-u>zz")
end

-- Set ctrl+s for save
vim.keymap.set("i", "<C-s>", "<esc>:w<cr>", { silent = true })
vim.keymap.set("n", "<C-s>", ":w<cr>", { silent = true })
vim.keymap.set("v", "<C-s>", ":w<cr>", { silent = true })

-- Set ctrl+w for close tab
vim.keymap.set("n", "<C-w><C-w>", ":bd<cr>:bp<cr>", { silent = true })

-- Copilot
-- vim.g.copilot_no_tab_map = true
-- vim.api.nvim_set_keymap("i", "<C-J>", 'copilot#Accept("<CR>")', { silent = true, expr = true })

-- Window management
-- vim.keymap.set("n", "<C-l>", "<C-W>l", { silent = true })
-- vim.keymap.set("n", "<C-h>", "<C-W>h", { silent = true })
-- vim.keymap.set("n", "<C-k>", "<C-W>k", { silent = true })
-- vim.keymap.set("n", "<C-j>", "<C-W>j", { silent = true })
vim.keymap.set("n", "<C-l>", ":TmuxNavigateRight<CR>", { silent = true })
vim.keymap.set("n", "<C-h>", ":TmuxNavigateLeft<CR>", { silent = true })
vim.keymap.set("n", "<C-k>", ":TmuxNavigateUp<CR>", { silent = true })
vim.keymap.set("n", "<C-j>", ":TmuxNavigateDown<CR>", { silent = true })

vim.keymap.set("n", "<C-Right>", ":vsp<cr>", { silent = true })
vim.keymap.set("n", "<C-Down>", ":sp<cr>", { silent = true })

vim.keymap.set("n", "<A-k>", ":resize -2<cr>", { silent = true })
vim.keymap.set("n", "<A-j>", ":resize +2<cr>", { silent = true })
vim.keymap.set("n", "<A-h>", ":vertical resize -2<cr>", { silent = true })
vim.keymap.set("n", "<A-l>", ":vertical resize +2<cr>", { silent = true })

vim.keymap.set("n", "<leader>=", ":vertical resize 50<cr>", { silent = true })

-- Set ctrl+q for quit
vim.keymap.set("n", "<C-q><C-q>", ":qa<cr>", { silent = true })

-- Move lines
vim.keymap.set("v", "J", ":m '>+1<CR>gv=gv", { silent = true })
vim.keymap.set("v", "K", ":m '<-2<CR>gv=gv", { silent = true })

-- Better search
vim.keymap.set("n", "<leader>ss", ":nohl<cr>", { silent = true })
vim.keymap.set("n", "n", "nzzzv", { silent = true })
vim.keymap.set("n", "N", "Nzzzv", { silent = true })
vim.keymap.set("n", "<leader>s", ":%s/\\<<C-r><C-w>\\>/<C-r><C-w>/gI<Left><Left><Left>")

-- Telescope
local builtin = require("telescope.builtin")
vim.keymap.set("n", "<leader>fa", function()
	builtin.find_files({
		find_command = {
			"rg",
			"--color=never",
			"--no-heading",
			"--files",
			"--hidden",
			"--no-ignore",
			"--sort",
			"path",
			"--glob",
			"!**/.git/*",
		},
	})
end, {})
vim.keymap.set("n", "<leader>fgg", builtin.live_grep, {})
vim.keymap.set("n", "<leader>fga", function()
	return builtin.live_grep({
		glob_pattern = {
			"!**/.git/*",
		},
	})
end, {})
vim.keymap.set("n", "<leader>ff", builtin.find_files, {})
vim.keymap.set("n", "<leader>fh", builtin.help_tags, {})
vim.keymap.set("n", "<leader>fd", builtin.diagnostics, {})
vim.keymap.set("n", "<leader>ft", ":TodoTelescope<cr>", {})
vim.keymap.set("n", "<leader>fc", ":Telescope yank_history<cr>", {})
vim.keymap.set("n", "<C-t>", builtin.buffers, {})

-- Tabs
vim.keymap.set("n", "<C-Tab>", ":bn<cr>", { silent = true })

-- Git
vim.keymap.set("n", "<leader>gs", ":DiffviewOpen<cr>", { silent = true })
vim.keymap.set("n", "<leader>gq", ":DiffviewClose<cr>", { silent = true })
vim.keymap.set("n", "<leader>gc", ":Git commit<cr>", { silent = true })
vim.keymap.set("n", "<leader>gp", ":Git push<cr>", { silent = true })
vim.keymap.set("n", "<leader>gb", ":Git blame<cr>", { silent = true })
vim.keymap.set("n", "<leader>gl", ":Git log<cr>", { silent = true })
vim.keymap.set("n", "<leader>gt", ":Flog<cr>", { silent = true })

-- Minimap
vim.keymap.set("n", "<leader>mm", ":MinimapToggle<cr>", { silent = true })

-- NvimTree
vim.keymap.set("n", "<leader>tf", ":NvimTreeFocus<CR>", { silent = true })
vim.keymap.set("n", "<leader>tc", ":NvimTreeClose<CR>", { silent = true })
vim.keymap.set("n", "<leader>to", ":NvimTreeOpen<CR>", { silent = true })
vim.keymap.set("n", "<leader>tt", ":NvimTreeFindFile<CR>", { silent = true })

-- UndoTree
vim.keymap.set("n", "<leader>tu", ":UndotreeToggle<CR>", { silent = true })

-- Set indent level
vim.keymap.set("n", "<leader>2", ":set shiftwidth=2 tabstop=2<CR>", { silent = true })
vim.keymap.set("n", "<leader>4", ":set shiftwidth=4 tabstop=4<CR>", { silent = true })

-- Diagnostics
vim.keymap.set("n", "<leader><leader>dt", ":TroubleToggle<CR>", { silent = true })
vim.keymap.set("n", "<leader><leader>dc", ":TodoTrouble<CR>", { silent = true })

-- Errors LSP
vim.keymap.set("n", "<leader>ep", ":lua vim.diagnostic.open_float(0, {scope = 'line'})<cr>")

-- Search all
vim.keymap.set("n", "<leader><leader>ff", ":Farr<Cr>", { silent = true })
vim.keymap.set("n", "<leader><leader>fu", ":Farundo<Cr>", { silent = true })

-- Code actions
vim.keymap.set("n", "<leader>a", ":lua vim.lsp.buf.code_action()<CR>", { silent = true })

-- Harpoon shortcuts
vim.keymap.set("n", "<leader>tm", ':lua require("harpoon.mark").add_file()<CR>', { silent = true })
vim.keymap.set("n", "<leader>th", ':lua require("harpoon.ui").toggle_quick_menu()<CR>', { silent = true })

-- Surround
vim.keymap.set("v", "s", "<Plug>VSurround", { silent = true })
