# QEMU test VM. Same modules as the laptop, same btrfs layout, minus the
# laptop hardware (NVIDIA, firmware).
{
  config,
  lib,
  pkgs,
  modulesPath,
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

  # `nix run .#vm` shares the host's dotfiles checkout here (9p): host
  # edits show up live, and `nixos-rebuild` in the VM builds the
  # uncommitted working tree. Without the share (e.g. virt-manager),
  # modules/dotfiles.nix provisions a checkout instead.
  fileSystems.${dotfiles} = {
    device = "dotfiles";
    fsType = "9p";
    options = [
      "trans=virtio"
      "version=9p2000.L"
      "msize=1048576"
      "nofail"
    ];
  };
}
