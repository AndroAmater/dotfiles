# The dotfiles are still shared with Arch and hardcode a few FHS paths.
# Instead of forking them, expose those paths here. Drop entries as the
# dotfiles are made path-agnostic.
{ pkgs, ... }:

{
  systemd.tmpfiles.rules = [
    # hypr/hyprland.conf: exec-once = /usr/lib/polkit-gnome/...
    "L+ /usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1 - - - - ${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1"
    # .zshrc: source /usr/share/fzf/key-bindings.zsh
    "L+ /usr/share/fzf/key-bindings.zsh - - - - ${pkgs.fzf}/share/fzf/key-bindings.zsh"
    # tmux/tmux.conf: default-shell /bin/zsh
    "L+ /bin/zsh - - - - ${pkgs.zsh}/bin/zsh"
  ];
}
