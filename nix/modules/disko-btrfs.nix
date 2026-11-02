# Single-disk layout: 1G ESP + LUKS2-encrypted btrfs with subvolumes.
# Hosts set `disko.devices.disk.main.device`.
#
# disko asks for the LUKS passphrase when it formats the disk (no
# passwordFile, so it never touches the repo or the nix store); the initrd
# asks for it on every boot. Only the ESP (/boot: kernel, initrd, systemd-boot)
# is unencrypted.
{ ... }:

let
  mountOptions = [
    "compress=zstd"
    "noatime"
  ];
in
{
  disko.devices.disk.main = {
    type = "disk";
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
            type = "luks";
            name = "cryptroot";
            # SSD TRIM through dm-crypt (leaks which blocks are free, not
            # their contents).
            settings.allowDiscards = true;
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
                # snapper's snapshots of /home (see below). A separate
                # top-level subvolume, so snapshots never contain snapshots.
                "@home-snapshots" = {
                  mountpoint = "/home/.snapshots";
                  inherit mountOptions;
                };
              };
            };
          };
        };
      };
    };
  };

  # Hourly snapshots of /home, to get back deleted or overwritten files
  # (same disk, so not a backup). The system itself is covered by NixOS
  # generations. `snapper -c home list`, files are under
  # /home/.snapshots/<n>/snapshot/.
  services.snapper = {
    # Catch up on a missed hourly snapshot after the laptop was off.
    persistentTimer = true;
    configs.home = {
      SUBVOLUME = "/home";
      ALLOW_USERS = [ "andrejf" ];
      # Lets andrejf browse /home/.snapshots without sudo.
      SYNC_ACL = true;
      TIMELINE_CREATE = true;
      TIMELINE_CLEANUP = true;
      TIMELINE_LIMIT_HOURLY = 24;
      TIMELINE_LIMIT_DAILY = 7;
      TIMELINE_LIMIT_WEEKLY = 4;
      TIMELINE_LIMIT_MONTHLY = 0;
      TIMELINE_LIMIT_QUARTERLY = 0;
      TIMELINE_LIMIT_YEARLY = 0;
    };
  };

  # Snapshots skip nested subvolumes, so making ~/.cache one keeps cache
  # churn (package/build caches) out of them. `v` creates it before
  # home-manager first touches ~/.cache; an existing directory is left alone.
  systemd.tmpfiles.rules = [ "v /home/andrejf/.cache 0700 andrejf users -" ];

  # Monthly scrub to catch silent corruption early.
  services.btrfs.autoScrub = {
    enable = true;
    interval = "monthly";
    fileSystems = [ "/" ];
  };
}
