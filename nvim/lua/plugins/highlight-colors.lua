return {
	"brenoprata10/nvim-highlight-colors",
	config = function()
		require("nvim-highlight-colors").setup({
			render = "background",
			enable_named_colors = true,
		})
		require("nvim-highlight-colors").turnOn()
	end,
}
