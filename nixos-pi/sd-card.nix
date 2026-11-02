# Read-only SD card.
#
# The SD card's ext4 partition (built by nixpkgs' sd-image) only holds /nix and
# /boot. It is mounted read-only on /sd, and /nix and /boot are bind mounts into
# it. / is a tmpfs, so the system tree is rebuilt on every boot and all mutable
# state lives on the SSD (storage.nix).
#
# Writing to the card (rebuilds, garbage collection) needs `sudo sd-rw` first
# and `sudo sd-ro` afterwards. `sudo pi-rebuild <nixos-rebuild args>` does both.
{
  config,
  lib,
  pkgs,
  modulesPath,
  ...
}:

let
  sdLabel = config.sdImage.rootVolumeLabel;
  registrationFile = config.sdImage.nixPathRegistrationFile;

  # Bind mounts copy the read-only flag of /sd, so each one is remounted too.
  remountSd = mode: ''
    mount -o remount,${mode} /sd
    mount -o remount,${mode},bind /nix
    mount -o remount,${mode},bind /boot
  '';

  # The daemon socket has ConditionPathIsReadWrite on the store, so it only starts while the
  # card is writable. While it listens on a read-only card, every nix command fails to start
  # the daemon, and the socket soon gives up for good (trigger limit).
  sd-rw = pkgs.writeShellApplication {
    name = "sd-rw";
    runtimeInputs = [
      pkgs.util-linux
      config.systemd.package
    ];
    text = ''
      ${remountSd "rw"}
      systemctl reset-failed nix-daemon.socket nix-daemon.service
      systemctl start nix-daemon.socket
      echo "SD card is writable, run sd-ro when done."
    '';
  };

  sd-ro = pkgs.writeShellApplication {
    name = "sd-ro";
    runtimeInputs = [
      pkgs.util-linux
      config.systemd.package
    ];
    text = ''
      # The daemon keeps the store database open.
      systemctl stop nix-daemon.socket nix-daemon.service
      sync
      ${remountSd "ro"}
      echo "SD card is read-only."
    '';
  };

  pi-rebuild = pkgs.writeShellApplication {
    name = "pi-rebuild";
    runtimeInputs = [
      sd-rw
      sd-ro
    ];
    text = ''
      sd-rw
      trap sd-ro EXIT
      nixos-rebuild "$@"
    '';
  };
in
{
  imports = [ "${modulesPath}/installer/sd-card/sd-image.nix" ];

  boot.loader.grub.enable = false;
  boot.loader.generic-extlinux-compatible.enable = true;

  sdImage.populateRootCommands = ''
    mkdir -p ./files/boot
    ${config.boot.loader.generic-extlinux-compatible.populateCmd} -c ${config.system.build.toplevel} -d ./files/boot
  '';
  # Upstream's resize service grows whatever is mounted on /, which is the tmpfs
  # here. sd-first-boot below grows the card instead.
  sdImage.expandOnBoot = false;
  sdImage.nixPathRegistrationFile = "/sd/nix-path-registration";

  fileSystems = {
    "/" = lib.mkForce {
      device = "none";
      fsType = "tmpfs";
      options = [
        "mode=755"
        "size=1G"
      ];
    };
    "/sd" = {
      device = "/dev/disk/by-label/${sdLabel}";
      fsType = "ext4";
      options = [
        "ro"
        "noatime"
      ];
      neededForBoot = true;
    };
    "/nix" = {
      device = "/sd/nix";
      fsType = "none";
      options = [ "bind" ];
      depends = [ "/sd" ];
      neededForBoot = true;
    };
    "/boot" = {
      device = "/sd/boot";
      fsType = "none";
      options = [ "bind" ];
      depends = [ "/sd" ];
    };
  };

  # The first boot has to write to the card: grow the partition, load the store
  # database (register-nix-paths from sd-image.nix) and let tmpfiles create the
  # gcroots symlinks. Their targets are constant (/run/current-system,
  # /run/booted-system), so later read-only boots have nothing to write.
  systemd.services.sd-first-boot = {
    description = "Make the SD card writable and grow it for the first boot";
    unitConfig = {
      DefaultDependencies = false;
      ConditionPathExists = registrationFile;
    };
    wantedBy = [ "sysinit.target" ];
    after = [ "local-fs.target" ];
    before = [
      "sysinit.target"
      "shutdown.target"
      "register-nix-paths.service"
      "systemd-tmpfiles-setup.service"
      "nix-daemon.socket"
    ];
    conflicts = [ "shutdown.target" ];
    restartIfChanged = false;
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    path = [
      pkgs.util-linux
      pkgs.parted
      pkgs.e2fsprogs
    ];
    script = ''
      ${remountSd "rw"}
      touch /run/sd-first-boot

      part=$(findmnt -n -o SOURCE /sd)
      disk=$(lsblk -npo PKNAME "$part")
      partNum=$(cat "/sys/class/block/$(basename "$part")/partition")
      echo ",+," | sfdisk -N"$partNum" --no-reread "$disk"
      partprobe "$disk"
      resize2fs "$part"
    '';
  };

  systemd.services.sd-first-boot-done = {
    description = "Make the SD card read-only after the first boot";
    unitConfig = {
      DefaultDependencies = false;
      ConditionPathExists = "/run/sd-first-boot";
    };
    wantedBy = [ "sysinit.target" ];
    after = [
      "sd-first-boot.service"
      "register-nix-paths.service"
      "systemd-tmpfiles-setup.service"
    ];
    before = [
      "sysinit.target"
      "shutdown.target"
      "nix-daemon.socket"
    ];
    conflicts = [ "shutdown.target" ];
    restartIfChanged = false;
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    path = [ pkgs.util-linux ];
    script = ''
      sync
      ${remountSd "ro"}
    '';
  };

  # Nix builds go to the SSD rather than the tmpfs root.
  systemd.services.nix-daemon.environment.TMPDIR = "/var/tmp";

  # GC and optimisation would write to the card on a timer.
  nix.gc.automatic = false;
  nix.optimise.automatic = false;
  nix.channel.enable = false;

  # Nothing in /etc survives a reboot, so users and identity are declarative.
  users.mutableUsers = false;
  environment.etc."machine-id".text = "603ecc66813b4d2987a1659e376bf01e\n";
  services.openssh.hostKeys = [
    {
      path = "/var/lib/ssh/ssh_host_ed25519_key";
      type = "ed25519";
    }
  ];

  environment.systemPackages = [
    sd-rw
    sd-ro
    pi-rebuild
  ];
}
