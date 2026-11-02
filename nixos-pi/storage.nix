{
  imports = [ ./disk-layout.nix ];

  # Activation creates home directories in the initrd, before stage 2 mounts.
  fileSystems."/home".neededForBoot = true;

  services.btrfs.autoScrub = {
    enable = true;
    fileSystems = [ "/var" ];
  };
}
