{
  description = "NixOS for the Raspberry Pi 4 (read-only SD card, btrfs SSD storage)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    { self, nixpkgs, disko, ... }:
    let
      pkgs = nixpkgs.legacyPackages.x86_64-linux;

      # The SSD layout evaluated for this x86_64 machine, so it can be formatted here.
      ssdScripts =
        (nixpkgs.lib.nixosSystem {
          modules = [
            disko.nixosModules.disko
            ./disk-layout.nix
            { nixpkgs.hostPlatform = "x86_64-linux"; }
          ];
        }).config.system.build;
    in
    {
      nixosConfigurations.pi = nixpkgs.lib.nixosSystem {
        modules = [
          disko.nixosModules.disko
          ./hardware.nix
          ./sd-card.nix
          ./storage.nix
          ./configuration.nix
        ];
      };

      # nix build .#sd-image
      packages.aarch64-linux.sd-image = self.nixosConfigurations.pi.config.system.build.sdImage;
      packages.x86_64-linux.sd-image = self.packages.aarch64-linux.sd-image;

      # sudo nix run .#format-ssd -- wipes the SSD (asks first) and creates the layout.
      apps.x86_64-linux.format-ssd = {
        type = "app";
        program = toString (
          pkgs.writeShellScript "format-ssd" ''
            set -euo pipefail
            ${ssdScripts.destroy}/bin/disko-destroy "$@"
            ${ssdScripts.format}/bin/disko-format
          ''
        );
      };

      # Boots the same layout (read-only SD + btrfs SSD) in an x86_64 VM.
      # nix build .#checks.x86_64-linux.vm-test
      checks.x86_64-linux.vm-test = import ./test.nix { inherit pkgs disko; };
    };
}
