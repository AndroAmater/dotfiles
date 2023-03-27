!#/bin/sh

cp .zshrc ~/.zshrc
cp .tmux.conf ~/.tmux.conf
cp -r oh-my-posh ~/.config/oh-my-posh
cp -r nvim ~/.config/nvim
cp -r i3 ~/.config/i3

# Source tmux config
tmux source ~/.tmux.conf

