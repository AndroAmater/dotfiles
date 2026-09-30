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
            ./nix/home
            hostModule
          ];
        };
    in
    {
      nixosConfigurations = {
        andrej-laptop = mkHost ./nix/hosts/andrej-laptop;
        vm = mkHost ./nix/hosts/vm;
      };

      packages.${system} = {
        # Full install of the `vm` host on a btrfs qcow2, built by disko.
        vm-image = self.nixosConfigurations.vm.config.system.build.diskoImages;
        vm = nixpkgs.legacyPackages.${system}.callPackage ./nix/vm-runner.nix {
          image = self.packages.${system}.vm-image;
        };
      };

      apps.${system}.vm = {
        type = "app";
        program = "${self.packages.${system}.vm}/bin/run-nixos-vm";
      };
    };
}
