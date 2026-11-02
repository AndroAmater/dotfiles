# Raspberry Pi 4 specifics: platform, kernel and the firmware partition of the SD card.
{ pkgs, ... }:

{
  nixpkgs.hostPlatform = "aarch64-linux";

  # Mainline kernel, cached on cache.nixos.org. Pi 4 is booted via U-Boot + extlinux.
  boot.kernelPackages = pkgs.linuxPackages;

  boot.kernelParams = [
    "console=ttyS0,115200n8"
    "console=tty0"
    # The SSD enclosure's Realtek RTL9220 bridge (0bda:9220) reset every ~30 s under UAS,
    # stalling all I/O. Plain usb-storage (u) avoids it. Without UAS the bridge often reports the
    # SSD's write cache as disabled, so the kernel sent no cache flushes; y assumes write-back.
    "usb-storage.quirks=0bda:9220:uy"
    # It also fails to enter USB 3 link power saving (U1), which stalled I/O for ~30 s at a time.
    "usbcore.quirks=0bda:9220:k"
  ];

  # The SSD holds /var, so the initrd needs USB storage on the Pi 4's
  # PCIe-attached VL805 USB 3 controller.
  boot.initrd.availableKernelModules = [
    "pcie-brcmstb"
    "reset-raspberrypi"
    "xhci_pci"
    "usb_storage"
    "uas"
    "mmc_block"
    "sdhci_iproc"
  ];

  # Pi 4-only version of nixpkgs' sd-image-aarch64.nix firmware partition.
  sdImage.populateFirmwareCommands =
    let
      fw = "${pkgs.raspberrypifw}/share/raspberrypi/boot";
      configTxt = pkgs.writeText "config.txt" ''
        [pi4]
        kernel=u-boot-rpi4.bin
        enable_gic=1
        armstub=armstub8-gic.bin
        disable_overscan=1
        arm_boost=1

        [all]
        arm_64bit=1
        # U-Boot needs this regardless of whether the UART is used.
        enable_uart=1
        # Keep the firmware from clobbering the mainline kernel's framebuffer.
        avoid_warnings=1
      '';
    in
    ''
      (cd ${fw} && cp fixup4*.dat start4*.elf bcm2711-rpi-4-b.dtb bcm2711-rpi-400.dtb bcm2711-rpi-cm4.dtb $NIX_BUILD_TOP/firmware/)
      cp ${configTxt} firmware/config.txt
      cp ${pkgs.ubootRaspberryPi4_64bit}/u-boot.bin firmware/u-boot-rpi4.bin
      cp ${pkgs.raspberrypi-armstubs}/armstub8-gic.bin firmware/armstub8-gic.bin
    '';

  environment.systemPackages = [ pkgs.libraspberrypi ];
}
