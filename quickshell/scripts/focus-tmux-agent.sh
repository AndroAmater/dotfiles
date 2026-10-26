#!/usr/bin/env bash
# Show a tmux session/pane in the kitty window attached to tmux and focus it.
# Prefers a kitty window on workspace 1; opens a new one there if none is attached.
set -euo pipefail

session=$1
pane=${2:-}
bin=${TMUX_AGENTS_BIN:-$HOME/Documents/Projects/tmux-agents/target/release/tmux-agents}

declare -A kitty_workspace kitty_address
while read -r pid workspace address; do
    kitty_workspace[$pid]=$workspace
    kitty_address[$pid]=$address
done < <(hyprctl clients -j | jq -r '.[] | select(.class == "kitty") | "\(.pid) \(.workspace.id) \(.address)"')

# Walk each tmux client's process ancestry up to the kitty instance that owns it
client="" address=""
while read -r name pid; do
    while [[ $pid -gt 1 && -z ${kitty_address[$pid]:-} ]]; do
        pid=$(ps -o ppid= -p "$pid" | tr -d ' ') || break
    done
    [[ -n ${kitty_address[$pid]:-} ]] || continue
    if [[ -z $client || ${kitty_workspace[$pid]} == 1 ]]; then
        client=$name
        address=${kitty_address[$pid]}
    fi
    [[ ${kitty_workspace[$pid]} == 1 ]] && break
done < <(tmux list-clients -F '#{client_name} #{client_pid}')

if [[ -n $client ]]; then
    args=(switch --session "$session" --client "$client")
    [[ -n $pane ]] && args+=(--pane "$pane")
    "$bin" "${args[@]}"
    hyprctl dispatch focuswindow "address:$address" >/dev/null
else
    if [[ -n $pane ]]; then
        tmux select-window -t "$pane"
        tmux select-pane -t "$pane"
    fi
    hyprctl dispatch workspace 1 >/dev/null
    setsid -f kitty tmux attach-session -t "$session" >/dev/null 2>&1
fi
