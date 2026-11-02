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
  services.asusd.enable = true;
}
