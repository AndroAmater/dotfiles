-- Import the function from formatting.lua
local F = require("formatOnSave.formatters")

---Store the buffer's modified state
---@type table
local modified_state = {}

---On BufWritePre, store the modified state
local function capture_modified_state()
	local buf = vim.api.nvim_get_current_buf()
	modified_state[buf] = vim.bo.modified
end

---Set the auto formatter for a file type with specified formatters
---@param pattern string
---@param formatters table
local function setAutoFormat(pattern, formatters)
	local function run_formatters()
		---@type number
		local buf = vim.api.nvim_get_current_buf()
		-- If buffer was modified
		if modified_state[buf] then
			for _, formatter in pairs(formatters) do
				formatter()
			end
			vim.cmd('redraw | echohl WarningMsg | echo "Formatted ' .. pattern .. '" | echohl None')
		end
		-- Reset the modified state
		modified_state[buf] = nil
	end
	vim.api.nvim_create_autocmd({ "BufWritePre" }, {
		pattern = { pattern },
		callback = capture_modified_state,
	})
	vim.api.nvim_create_autocmd({ "BufWritePost" }, {
		pattern = { pattern },
		callback = run_formatters,
	})
end

-- JavaScript/TypeScript
-- setAutoFormat("*.js", {
-- 	F.prettier,
-- 	F.eslint,
-- })

-- setAutoFormat("*.ts", {
-- 	F.prettier,
-- 	F.eslint,
-- })

-- setAutoFormat("*.json", {
-- 	F.prettier,
-- })

-- setAutoFormat("*.md", {
-- 	F.prettier,
-- })

-- setAutoFormat("*.yml", {
-- 	F.prettier,
-- })

-- setAutoFormat("*.yaml", {
-- 	F.prettier,
-- })

-- setAutoFormat("*.vue", {
-- 	F.prettier,
-- 	F.eslint,
-- })

-- setAutoFormat("*.html", {
-- 	F.prettier,
-- })

-- setAutoFormat("*.scss", {
-- 	F.prettier,
-- })

-- -- Lua

-- setAutoFormat("*.lua", {
-- 	F.stylua,
-- })

-- -- Go
-- setAutoFormat("*.go", {
-- 	F.gofmt,
-- })

-- -- PHP

-- setAutoFormat("*.php", {
-- 	F.prettier,
-- })

local augroup = vim.api.nvim_create_augroup
local autocmd = vim.api.nvim_create_autocmd
augroup("__formatter__", { clear = true })
autocmd("BufWritePost", {
	group = "__formatter__",
	command = ":FormatWrite",
})
