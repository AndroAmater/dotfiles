# The laptop config installed on the external USB SSD (Samsung 980 PRO in
# the Ugreen enclosure), for trying NixOS without touching the Arch disk.
{ lib, ... }:

{
  imports = [ ../andrej-laptop ];

  networking.hostName = lib.mkForce "andrej-external";

  # WARNING: `disko` wipes this disk.
  disko.devices.disk.main.device =
    lib.mkForce "/dev/disk/by-id/usb-Samsung_SSD_980_PRO_1TB_01326800019B-0:0";

  # The root filesystem is on USB, so initrd needs the USB storage drivers.
  boot.initrd.availableKernelModules = [
    "usb_storage"
    "uas"
    "sd_mod"
  ];

  # Leave the laptop's firmware boot entries alone; systemd-boot also
  # installs the removable-media fallback loader (EFI/BOOT/BOOTX64.EFI),
  # which the firmware's boot menu picks up for the USB disk.
  boot.loader.efi.canTouchEfiVariables = lib.mkForce false;
}
