local F = {}

F.stylua = function()
	vim.cmd("!stylua " .. vim.fn.expand("%"))
end

F.eslint = function()
	vim.cmd("silent !eslint_d --fix " .. vim.fn.expand("%"))
end

F.prettier = function()
	vim.cmd("silent !npx prettier --write " .. vim.fn.expand("%"))
end

F.prettierd = function()
	vim.cmd(
		'silent !file='..vim.fn.expand("%")..'; output=$(cat $file | prettierd $file); [[ "$output" \\!= "No files specified" ]] && printf "\\%s" "$output" | tee $file'
	)
end

return F
