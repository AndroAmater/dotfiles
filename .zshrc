# Set default editor
EDITOR="nvim"

# Export yarn bin paths
export PATH="$PATH:$(yarn global bin)"
export PATH="$PATH:/home/andrejf/.cargo/bin"

# Configure oh-my-posh
eval "$(oh-my-posh init zsh --config ~/.config/oh-my-posh/config.json)"

# Source fzf keybindings
source /usr/share/fzf/key-bindings.zsh

# Aliases
alias go-hl="cd /home/andrejf/Documents/Hudlajf"
alias core="./core.pex"
alias dc="docker-compose"
alias composer7="php7 /usr/bin/composer install"
alias sssh='kitty +kitten ssh'
alias nv="neovide --maximized --multigrid --noidle ."
alias cdc="cd ~/.config/"
alias nodelegacyfix="export NODE_OPTIONS=--openssl-legacy-provider"

# Build rust crate for any docker container
alias rust-musl-builder='docker run --rm -it -v "$(pwd)":/home/rust/src ekidd/rust-musl-builder'
