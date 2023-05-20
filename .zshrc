# Set default editor
EDITOR="nvim"

export PATH="$PATH:$(yarn global bin)"
export PATH="$PATH:/home/andrejf/.cargo/bin"
export PATH=~/.config/composer/vendor/bin:$PATH

# Configure oh-my-posh
eval "$(oh-my-posh init zsh --config ~/.config/oh-my-posh/config.json)"

# Source fzf keybindings
source /usr/share/fzf/key-bindings.zsh

# Aliases
alias go-hl="cd /home/andrejf/Documents/Hudlajf"
alias go-pr="cd /home/andrejf/Documents/Projects"
alias core="./core.pex"
alias dc="docker-compose"
alias composer7="php7 /usr/bin/composer install"
alias sssh='kitty +kitten ssh'
alias nv="neovide --maximized --multigrid --noidle ."
alias nvs="nvim -S Session.vim ."
alias cdc="cd ~/.config/"
alias nodelegacyfix="export NODE_OPTIONS=--openssl-legacy-provider"
alias runner-start='docker run -itd -v /srv/gitlab-runner/config:/etc/gitlab-runner -v /var/run/docker.sock:/var/run/docker.sock --name="gitlab-runner" gitlab/gitlab-runner run'
alias runner-reset="docker kill gitlab-runner ; docker rm gitlab-runner ; runner-start"

# Build rust crate for any docker container
alias rust-musl-builder='docker run --rm -it -v "$(pwd)":/home/rust/src ekidd/rust-musl-builder'
