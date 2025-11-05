# Set default editor
export EDITOR="nvim"
export VISUAL="nvim"

# Update PATH
export PATH="$PATH:$(yarn global bin)"
export PATH="$PATH:$HOME/.cargo/bin"
export PATH=~/.config/composer/vendor/bin:$PATH
export PATH="$HOME/.local/bin:$PATH"
export PATH="$HOME/go/bin:$PATH"
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"
export KUBECONFIG=/etc/kubernetes/cluster-admin.kubeconfig

# bun completions
[ -s "/home/andrejf/.bun/_bun" ] && source "/home/andrejf/.bun/_bun"

# Enable compdef
autoload -Uz compinit && compinit

# Configure oh-my-posh
eval "$(oh-my-posh init zsh --config ~/.config/oh-my-posh/config.json)"

# Aliases
alias go-hl="cd $HOME/Documents/Hudlajf"
alias go-pr="cd $HOME/Documents/Projects"
alias dc="docker-compose"
alias ddd="docker compose down && docker compose up -d --build && docker compose logs -f"
alias ddj="docker compose down && docker compose up -d --build && make logs-jq"
alias sssh='kitty +kitten ssh'
alias lg="lazygit"
alias c="clear"
alias n="nvim"
alias sz="source ~/.zshrc"
alias ll="exa --long --header --git --group --icons --all"
alias lt="exa --tree --long --header --git --group --icons --all"
alias mb="brightnessctl set 40%"
alias fb="brightnessctl set 100%"
alias kcp="kubectl --context do-fra1-codedjen-production"
alias kcg="kubectl --context do-fra1-codedjen-customer-apps"
alias gpa="pbpaste | git apply"

# Codecannon aliases
alias dcg="docker compose exec generator sh"
alias dca="docker compose exec api sh"
alias dcs="docker compose exec shepherd sh"
alias dcu="docker compose exec ui sh"

# Build rust crate for any docker container
alias rust-musl-builder='docker run --rm -it -v "$(pwd)":/home/rust/src ekidd/rust-musl-builder'

# Share history between terminals
setopt share_history

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

# Figure out if script runs on mac or Linux
unameOut="$(uname -s)"
case "${unameOut}" in
    Linux*)     machine=Linux;;
    Darwin*)    machine=Mac;;
    CYGWIN*)    machine=Cygwin;;
    MINGW*)     machine=MinGw;;
    *)          machine="UNKNOWN:${unameOut}"
esac

if [ "$machine" = "Mac" ]; then
    # Enable pyenv (LeanIX)
    eval "$(pyenv init --path)"
    eval "$(pyenv virtualenv-init -)"

    # (LEANIX specific)
    [ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
    [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

    export PATH="$HOME/.yarn/bin:$HOME/.config/yarn/global/node_modules/.bin:$PATH"

    ulimit -n 10204
    ulimit -s 10204

	defaults write -g ApplePressAndHoldEnabled -bool false
elif [ "$(expr substr $(uname -s) 1 5)" = "Linux" ]; then
    # code for GNU/Linux platform

    # Source fzf keybindings
    source /usr/share/fzf/key-bindings.zsh
fi

# Set keyboard repeart rate and delay
xset r rate 175 60

twitterify () {
  if [ -z "$1" ]; then
    echo "Usage: twenc <basename>"
    echo "Example: twenc 11   # reads 11.mov and writes 11_twitter.mp4"
    return 1
  fi

  local base="$1"
  local in=""

  # Try common video extensions if you don't include one.
  for ext in mov mp4 m4v mkv; do
    if [ -f "${base}.${ext}" ]; then
      in="${base}.${ext}"
      break
    fi
  done

  if [ -z "$in" ]; then
    echo "Input not found. Looked for: ${base}.mov/.mp4/.m4v/.mkv"
    return 1
  fi

  local out="${base}_twitter.mp4"

  ffmpeg -i "$in" \
    -map 0:v:0 -map 0:a:0 \
    -c:v libx264 -profile:v high -level 4.2 -pix_fmt yuv420p \
    -c:a aac -profile:a aac_low -b:a 320k -ar 48000 -ac 2 \
    -movflags +faststart \
    "$out"
}
