# QEMU test VM. Same modules as the laptop, same btrfs layout, minus the
# laptop hardware (NVIDIA, firmware).
{
  config,
  lib,
  pkgs,
  modulesPath,
  self,
  ...
}:

let
  user = "andrejf";
  dotfiles = "/home/${user}/.config/dotfiles";
in
{
  imports = [ (modulesPath + "/profiles/qemu-guest.nix") ];

  networking.hostName = "andrej-vm";

  disko.devices.disk.main = {
    device = "/dev/vda";
    imageSize = "64G";
  };
  disko.memSize = 4096;
  disko.imageBuilder.imageFormat = "qcow2";

  # disko passes an aggregated module tree as vmTools' `kernel`, which
  # current nixpkgs rejects (it now wants that as `kernelModules`).
  # Remove once disko adapts.
  disko.imageBuilder.pkgs = pkgs // {
    vmTools = pkgs.vmTools // {
      override =
        args:
        pkgs.vmTools.override (
          args
          // lib.optionalAttrs (args ? kernel) {
            kernel = config.disko.imageBuilder.kernelPackages.kernel;
            kernelModules = args.kernel;
          }
        );
    };
  };

  # No persistent EFI vars needed; systemd-boot also installs the
  # removable-media fallback loader that OVMF boots.
  boot.loader.efi.canTouchEfiVariables = lib.mkForce false;
  boot.initrd.availableKernelModules = [
    "virtio_pci"
    "virtio_blk"
    "virtio_net"
    "virtio_gpu"
  ];

  hardware.graphics.enable = true;
  services.qemuGuest.enable = true;

  # The dotfiles are linked from ~/.config/dotfiles. In the VM, seed that
  # checkout from this flake's source on first boot (writable copy).
  systemd.services.seed-dotfiles = {
    description = "Seed ~/.config/dotfiles from the flake source";
    wantedBy = [ "multi-user.target" ];
    before = [ "display-manager.service" ];
    unitConfig.ConditionPathExists = "!${dotfiles}";
    serviceConfig.Type = "oneshot";
    script = ''
      ${pkgs.coreutils}/bin/install -d -o ${user} -g users /home/${user}/.config
      ${pkgs.coreutils}/bin/cp -r --no-preserve=mode,ownership ${self} ${dotfiles}
      ${pkgs.coreutils}/bin/chown -R ${user}:users ${dotfiles}
      ${pkgs.findutils}/bin/find ${dotfiles} -type f \
        \( -name '*.sh' -o -path '*/scripts/*' -o -path '*/tmux/templates/*' -o -name set-monitor \) \
        -exec ${pkgs.coreutils}/bin/chmod +x {} +
    '';
  };
}
