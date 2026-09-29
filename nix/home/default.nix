# Links the dotfiles into $HOME the same way link.sh / install-dotfiles.yml do.
# Links point at the live checkout (not the nix store) so edits apply
# immediately and tools that write into their config dir keep working.
{ inputs, ... }:

let
  user = "andrejf";
  home = "/home/${user}";
  dotfiles = "${home}/.config/dotfiles";
in
{
  home-manager.useGlobalPkgs = true;
  home-manager.useUserPackages = true;

  home-manager.users.${user} =
    { config, ... }:
    let
      link = path: config.lib.file.mkOutOfStoreSymlink "${dotfiles}/${path}";
    in
    {
      home.username = user;
      home.homeDirectory = home;
      home.stateVersion = "26.05";

      home.file.".zshrc".source = link ".zshrc";
      home.file.".tmux/plugins/tpm".source = inputs.tpm;

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
      };

      dconf.settings."org/gnome/desktop/interface".color-scheme = "prefer-dark";
    };
}
