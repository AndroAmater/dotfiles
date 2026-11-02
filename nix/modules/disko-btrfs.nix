# Single-disk layout: 1G ESP + btrfs with subvolumes.
# Hosts set `disko.devices.disk.main.device`.
{ lib, ... }:

let
  mountOptions = [
    "compress=zstd"
    "noatime"
  ];
in
{
  disko.devices.disk.main = {
    type = "disk";
    device = lib.mkDefault "/dev/vda";
    content = {
      type = "gpt";
      partitions = {
        ESP = {
          size = "1G";
          type = "EF00";
          content = {
            type = "filesystem";
            format = "vfat";
            mountpoint = "/boot";
            mountOptions = [ "umask=0077" ];
          };
        };
        root = {
          size = "100%";
          content = {
            type = "btrfs";
            extraArgs = [ "-f" ];
            subvolumes = {
              "@" = {
                mountpoint = "/";
                inherit mountOptions;
              };
              "@home" = {
                mountpoint = "/home";
                inherit mountOptions;
              };
              "@nix" = {
                mountpoint = "/nix";
                inherit mountOptions;
              };
              "@log" = {
                mountpoint = "/var/log";
                inherit mountOptions;
              };
              "@snapshots" = {
                mountpoint = "/.snapshots";
                inherit mountOptions;
              };
            };
          };
        };
      };
    };
  };

  # Monthly scrub to catch silent corruption early.
  services.btrfs.autoScrub = {
    enable = true;
    interval = "monthly";
    fileSystems = [ "/" ];
  };
}
