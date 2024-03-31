return {
	"gbprod/yanky.nvim",
	config = function()
		require("yanky").setup({
			ring = {
				history_length = 10000,
				storage = "shada",
				sync_with_numbered_registers = true,
				cancel_event = "update",
			},
			picker = {
				select = {
					action = nil,
				},
				telescope = {
					use_default_mappings = true,
					mappings = nil,
				},
			},
			system_clipboard = {
				sync_with_ring = true,
			},
			highlight = {
				on_put = false,
				on_yank = false,
			},
			preserve_cursor_position = {
				enabled = true,
			},
		})
		require("telescope").load_extension("yank_history")
	end,
}
