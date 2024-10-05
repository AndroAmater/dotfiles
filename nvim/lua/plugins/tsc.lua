return {
	-- 	"dmmulroy/tsc.nvim",
	-- 	config = function()
	-- 		function endsWith(str, ending)
	-- 			return ending == "" or string.sub(str, -string.len(ending)) == ending
	-- 		end

	-- 		local tscExecutable = (function()
	-- 			local node_modules_tsc_binary = vim.fn.findfile("node_modules/.bin/vue-tsc", ".;")
	-- 			if node_modules_tsc_binary ~= "" then
	-- 				return node_modules_tsc_binary
	-- 			end

	-- 			node_modules_tsc_binary = vim.fn.findfile("node_modules/.bin/tsc", ".;")
	-- 			if node_modules_tsc_binary ~= "" then
	-- 				return node_modules_tsc_binary
	-- 			end

	-- 			return "tsc"
	-- 		end)()

	-- 		function makeFlags()
	-- 			if vim.fn.findfile("node_modules/.bin/vue-tsc", ".;") ~= "" then
	-- 				return { project = false, noEmit = false, build = true, force = true, watch = true }
	-- 			end
	-- 			return {}
	-- 		end

	-- 		require("tsc").setup({
	-- 			auto_open_qflist = false,
	-- 			auto_close_qflist = false,
	-- 			auto_focus_qflist = false,
	-- 			auto_start_watch_mode = true,
	-- 			use_trouble_qflist = true,
	-- 			bin_path = tscExecutable,
	-- 			enable_progress_notifications = true,
	-- 			flags = makeFlags(),
	-- 			hide_progress_notifications_from_history = true,
	-- 			spinner = { "⣾", "⣽", "⣻", "⢿", "⡿", "⣟", "⣯", "⣷" },
	-- 			pretty_errors = true,
	-- 		})
	-- 	end,
}
