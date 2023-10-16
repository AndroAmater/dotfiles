# Set default editor
export EDITOR="nvim"
export VISUAL="nvim"

# Update PATH
export PATH="$PATH:$(yarn global bin)"
export PATH="$PATH:$HOME/.cargo/bin"
export PATH=~/.config/composer/vendor/bin:$PATH
export PATH="$HOME/.local/bin:$PATH"
export PATH="$HOME/go/bin:$PATH"

# Enable compdef
autoload -Uz compinit && compinit

# Configure oh-my-posh
eval "$(oh-my-posh init zsh --config ~/.config/oh-my-posh/config.json)"

# Enable pyenv (LeanIX)
eval "$(pyenv init --path)"
eval "$(pyenv virtualenv-init -)"

# Source fzf keybindings
# source /usr/share/fzf/key-bindings.zsh

# Aliases
alias go-hl="cd $HOME/Documents/Hudlajf"
alias go-pr="cd $HOME/Documents/Projects"
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
alias gg="git-graph"
alias lg="lazygit"
alias c="clear"
alias n="nvim"
alias sz="source ~/.zshrc"
alias ll="exa --long --header --git --group --icons --all"
alias lt="exa --tree --long --header --git --group --icons --all"

# Build rust crate for any docker container
alias rust-musl-builder='docker run --rm -it -v "$(pwd)":/home/rust/src ekidd/rust-musl-builder'

# Tmux templates handler
function tt() {
    local tmux_template_dir="$HOME/.config/tmux/templates/"
    local tmux_template_name="$1"
    
    if [[ -f "$tmux_template_dir/$tmux_template_name" ]]; then
        bash "$tmux_template_dir/$tmux_template_name"
    else
        echo "No such template: $tmux_template_name"
    fi
}
_tt() {
    local tmux_template_dir="$HOME/.config/tmux/templates/"
    local tmux_templates=$(ls $tmux_template_dir)
    _arguments '1: :('"$tmux_templates"')'
}
compdef _tt tt

# (LEANIX specific)
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

export PATH="$HOME/.yarn/bin:$HOME/.config/yarn/global/node_modules/.bin:$PATH"

ulimit -n 10204
ulimit -s 10204
