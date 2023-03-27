if vim.g.vscode then
	vim.cmd('source ./plug.vim')
else
	require("packageManagers.lazynvim")
end

