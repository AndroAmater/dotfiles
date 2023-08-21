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

-- Format on save
require("formatOnSave")

local vim = vim

-- Function to call Go binary
_G.call_go_binary = function()
	-- Create a new buffer for the terminal
	local buf = vim.api.nvim_create_buf(false, true)

	-- Calculate window size
	local width = vim.api.nvim_get_option("columns")
	local height = vim.api.nvim_get_option("lines")

	-- Calculate the window positioning for middle of the screen
	local win_height = math.ceil(height * 0.8 - 4)
	local win_width = math.ceil(width * 0.8)
	local row = math.ceil((height - win_height) / 2 - 1)
	local col = math.ceil((width - win_width) / 2)

	-- Set window options
	local win_opts = {
		relative = "editor",
		width = win_width,
		height = win_height,
		row = row,
		col = col,
		anchor = "nw",
		style = "minimal",
		border = "rounded",
	}

	-- Create a new floating window
	local win = vim.api.nvim_open_win(buf, true, win_opts)
	vim.api.nvim_win_set_option(win, "winhl", "normal:normal")

	-- Run the Go binary inside the terminal
	local cmd = "gosearch --sidebar-only"
	-- vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(":terminal " .. cmd .. "<CR>", true, false, true), "n", true)
	local term = vim.fn.termopen(cmd, {
		on_exit = function()
			vim.api.nvim_win_close(win, 0)
		end,
	})
	vim.cmd.startinsert()

	local fifoFile = "/tmp/fifo" -- replace with your FIFO path

	-- Start a job that reads from the FIFO
	local job_id = vim.fn.jobstart({
		"tail",
		"-f",
		"-n",
		"+1",
		fifoFile,
	}, {
		on_stdout = function(_, d, j)
			-- When a file path is read from the FIFO, open that file
			if d[1] and #d[1] > 0 then
				vim.api.nvim_command("split " .. d[1])
				vim.fn.jobstop(j)
			end
		end,
	})
end

-- Register the command
vim.cmd("command! -nargs=0 GoHello :lua call_go_binary()")
