# External SSD: one GPT partition with btrfs subvolumes for all mutable state,
# Docker, bulk storage and a 32G swapfile. Used by disko both to format the
# drive (`nix run .#format-ssd`) and to generate the Pi's mounts.
{ lib, ... }:

let
  btrfsOptions = [
    "compress=zstd"
    "noatime"
  ];
in
{
  disko.devices.disk.ssd = {
    type = "disk";
    device = lib.mkDefault "/dev/disk/by-id/usb-Samsung_SSD_980_PRO_1TB_01326800019B-0:0";
    content = {
      type = "gpt";
      partitions.storage = {
        size = "100%";
        content = {
          type = "btrfs";
          extraArgs = [
            "-f"
            "-L"
            "pi-storage"
          ];
          subvolumes = {
            # /var is mounted in the initrd (systemd state, logs, ssh host keys, users).
            "/var" = {
              mountpoint = "/var";
              mountOptions = btrfsOptions;
            };
            "/home" = {
              mountpoint = "/home";
              mountOptions = btrfsOptions;
            };
            # Separate from /var so snapshots of /var don't drag images along.
            "/docker" = {
              mountpoint = "/var/lib/docker";
              mountOptions = btrfsOptions;
            };
            "/data" = {
              mountpoint = "/data";
              mountOptions = btrfsOptions;
            };
            # disko creates the swapfile with `btrfs filesystem mkswapfile` (NOCOW, uncompressed).
            "/swap" = {
              mountpoint = "/swap";
              mountOptions = [ "noatime" ];
              swap.swapfile.size = "32G";
            };
          };
        };
      };
    };
  };
}
