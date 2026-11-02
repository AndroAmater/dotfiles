# Links the dotfiles into $HOME the same way link.sh / install-dotfiles.yml do.
# Links point at the live checkout (not the nix store) so edits apply
# immediately and tools that write into their config dir keep working.
{ inputs, pkgs, ... }:

let
  user = "andrejf";
  home = "/home/${user}";
  dotfiles = "${home}/.config/dotfiles";
in
{
  home-manager.useGlobalPkgs = true;
  home-manager.useUserPackages = true;

  home-manager.users.${user} =
    { config, lib, ... }:
    let
      link = path: config.lib.file.mkOutOfStoreSymlink "${dotfiles}/${path}";
    in
    {
      home.username = user;
      home.homeDirectory = home;
      home.stateVersion = "26.05";

      home.file.".zshrc".source = link ".zshrc";
      home.file.".claude/settings.json".source = link "claude/settings.json";
      home.file.".tmux/plugins/tpm".source = inputs.tpm;

      # nixpkgs' docker has no bundled CLI plugins; `docker compose` and
      # `docker buildx` are looked up here.
      home.file.".docker/cli-plugins/docker-compose".source =
        "${pkgs.docker-compose}/libexec/docker/cli-plugins/docker-compose";
      home.file.".docker/cli-plugins/docker-buildx".source =
        "${pkgs.docker-buildx}/libexec/docker/cli-plugins/docker-buildx";

      xdg.configFile = {
        "nvim".source = link "nvim";
        "kitty".source = link "kitty";
        "oh-my-posh".source = link "oh-my-posh";
        "tmux".source = link "tmux";
        "hypr".source = link "hypr";
        "quickshell".source = link "quickshell";
        "lazygit".source = link "lazygit";
        "k9s".source = link "k9s";
        "jfind".source = link "jfind";
        "bat".source = link "bat";
        "opencode".source = link "opencode";
        "hyprwhspr".source = link "hyprwhspr";
        "git".source = link "git";
        "btop".source = link "btop";
        "nwg-displays".source = link "nwg-displays";
        "fontconfig/conf.d/75-emoji.conf".source = link "fontconfig/75-emoji.conf";
      };

      xdg.userDirs = {
        enable = true;
        createDirectories = true;
        projects = "${home}/Projects";
      };

      # bat/syntaxes (PHP highlighting in lazygit's delta) needs a cache rebuild.
      home.activation.batCache = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
        run ${pkgs.bat}/bin/bat cache --build >/dev/null
      '';

      dconf.settings."org/gnome/desktop/interface".color-scheme = "prefer-dark";
    };
}
