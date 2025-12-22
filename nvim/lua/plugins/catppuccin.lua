return {
	"catppuccin/nvim",
	name = "catppuccin",
	opts = {
		flavour = "mocha",
		background = {
			light = "latta",
			dark = "mocha",
		},
		styles = {
			comments = {},
			conditionals = {},
			loops = {},
			functions = {},
			keywords = {},
			strings = {},
			variables = {},
			numbers = {},
			booleans = {},
			properties = {},
			types = {},
		},
		transparent_background = false,
		custom_highlights = function(colors)
			return {
				Folded = { bg = colors.base, fg = colors.overlay0 }, -- line used for closed folds
				FoldColumn = { fg = colors.overlay0 }, -- 'foldcolumn'
			}
		end,
		color_overrides = {
			mocha = {
				-- rosewater = "#f5e0dc",
				-- flamingo = "#f2cdcd",
				-- pink = "#f5c2e7",
				-- mauve = "#cba6f7",
				-- red = "#f38ba8",
				-- maroon = "#eba0ac",
				-- peach = "#fab387",
				-- yellow = "#f9e2af",
				-- green = "#a6e3a1",
				-- teal = "#94e2d5",
				-- sky = "#89dceb",
				-- sapphire = "#74c7ec",
				-- blue = "#89b4fa",
				-- lavender = "#b4befe",
				-- text = "#cdd6f4",
				-- subtext1 = "#bac2de",
				-- subtext0 = "#a6adc8",
				overlay2 = "#767e9e",
				overlay1 = "#646982",
				overlay0 = "#545769",
				surface2 = "#414353",
				surface1 = "#2f303d",
				surface0 = "#1c1c26",
				base = "#0a0a0f",
				mantle = "#040406",
				crust = "#020203",
			},
		},
	},
}
