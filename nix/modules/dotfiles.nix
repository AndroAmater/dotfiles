# The dotfiles are linked (nix/home) from a live checkout at
# ~/.config/dotfiles, so edits apply without a rebuild and
# `nixos-rebuild --flake ~/.config/dotfiles` builds uncommitted changes.
# On every host, provision that checkout on first boot if it's missing:
# clone the repo, or copy this flake's source when offline.
{
  pkgs,
  utils,
  self,
  ...
}:

let
  user = "andrejf";
  dotfiles = "/home/${user}/.config/dotfiles";
  repo = "https://github.com/androamater/dotfiles";
in
{
  systemd.services.provision-dotfiles = {
    description = "Provision ~/.config/dotfiles";
    wantedBy = [ "multi-user.target" ];
    wants = [ "network-online.target" ];
    after = [
      "network-online.target"
      # A host may mount the checkout here instead (see hosts/vm).
      "${utils.escapeSystemdPath dotfiles}.mount"
    ];
    before = [ "display-manager.service" ];
    unitConfig = {
      ConditionPathIsMountPoint = "!${dotfiles}";
      ConditionDirectoryNotEmpty = "!${dotfiles}";
    };
    path = with pkgs; [
      coreutils
      findutils
      git
      util-linux
    ];
    serviceConfig.Type = "oneshot";
    script = ''
      install -d -o ${user} -g users /home/${user}/.config ${dotfiles}
      if timeout 120 runuser -u ${user} -- git clone ${repo} ${dotfiles}; then
        exit 0
      fi
      echo "clone failed, copying the flake source instead" >&2
      cp -rT --no-preserve=mode,ownership ${self} ${dotfiles}
      chown -R ${user}:users ${dotfiles}
      find ${dotfiles} -type f \
        \( -name '*.sh' -o -path '*/scripts/*' -o -path '*/tmux/templates/*' -o -name set-monitor \) \
        -exec chmod +x {} +
    '';
  };
}
