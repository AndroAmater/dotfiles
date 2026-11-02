{
  description = "andrejf's NixOS desktop";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Pinned to a release: nix/modules/hyprwhspr.nix patches its source.
    hyprwhspr = {
      url = "github:goodroot/hyprwhspr/v1.51.0";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # tmux.conf expects TPM at ~/.tmux/plugins/tpm
    tpm = {
      url = "github:tmux-plugins/tpm";
      flake = false;
    };
  };

  outputs =
    inputs@{ self, nixpkgs, ... }:
    let
      system = "x86_64-linux";

      mkHost =
        hostModule:
        nixpkgs.lib.nixosSystem {
          inherit system;
          specialArgs = { inherit inputs self; };
          modules = [
            inputs.disko.nixosModules.disko
            inputs.home-manager.nixosModules.home-manager
            ./nix/modules/common.nix
            ./nix/modules/desktop.nix
            ./nix/modules/packages.nix
            ./nix/modules/services.nix
            ./nix/modules/fhs-compat.nix
            ./nix/modules/dotfiles.nix
            ./nix/modules/hyprwhspr.nix
            ./nix/modules/jetbrains-toolbox.nix
            ./nix/home
            hostModule
          ];
        };
    in
    {
      nixosConfigurations = {
        andrej-laptop = mkHost ./nix/hosts/andrej-laptop;
        andrej-external = mkHost ./nix/hosts/andrej-external;
      };
    };
}
