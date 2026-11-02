# ASUS laptop: Ryzen 7 6800HS (Radeon 680M) + RTX 3070 Ti Laptop.
{ config, ... }:

{
  imports = [ ./hardware-configuration.nix ];

  networking.hostName = "andrej-laptop";

  # WARNING: `disko` wipes this disk. It is the current Arch disk
  # (Samsung 980 PRO, nvme1n1). Windows lives on the other NVMe, BUT its
  # bootloader (EFI/Microsoft) is on this disk's ESP. Back it up and copy
  # it back after formatting (see nix/README.md); systemd-boot then picks
  # Windows up automatically.
  disko.devices.disk.main.device = "/dev/disk/by-id/nvme-Samsung_SSD_980_PRO_1TB_S5GXNX0T356851L";

  hardware.enableRedistributableFirmware = true;
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  # Hybrid graphics: AMD iGPU drives the desktop, NVIDIA on demand
  # (`nvidia-offload <cmd>`).
  services.xserver.videoDrivers = [
    "amdgpu"
    "nvidia"
  ];
  hardware.nvidia = {
    open = true;
    modesetting.enable = true;
    package = config.boot.kernelPackages.nvidiaPackages.stable;
    powerManagement.enable = true;
    powerManagement.finegrained = true;
    prime = {
      offload = {
        enable = true;
        enableOffloadCmd = true;
      };
      amdgpuBusId = "PCI:7:0:0";
      nvidiaBusId = "PCI:1:0:0";
    };
  };

  services.power-profiles-daemon.enable = true;

  # Same asusd config as the Arch install: Quiet on battery, Performance
  # on AC, keyboard backlight.
  services.asusd = {
    enable = true;
    asusdConfig.source = ./asusd/asusd.ron;
    fanCurvesConfig.source = ./asusd/fan_curves.ron;
    auraConfigs."19b6".source = ./asusd/aura_19b6.ron;
  };

  home-manager.users.andrejf =
    { config, ... }:
    {
      xdg.configFile."rog".source =
        config.lib.file.mkOutOfStoreSymlink "/home/andrejf/.config/dotfiles/rog";
    };

  # Time to pick Windows in the boot menu (Arch had GRUB_TIMEOUT=30).
  boot.loader.timeout = 30;

  # Local dev hostnames from the Arch /etc/hosts.
  networking.hosts."127.0.0.1" = [
  ];
}
