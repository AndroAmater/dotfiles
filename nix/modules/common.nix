{ pkgs, ... }:

{
  imports = [ ./disko-btrfs.nix ];

  nix.settings = {
    experimental-features = [
      "nix-command"
      "flakes"
    ];
    trusted-users = [ "@wheel" ];
    auto-optimise-store = true;
  };

  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 14d";
  };

  nixpkgs.config.allowUnfree = true;

  boot.loader.systemd-boot = {
    enable = true;
    configurationLimit = 20;
  };
  boot.loader.efi.canTouchEfiVariables = true;
  boot.kernelPackages = pkgs.linuxPackages_latest;

  zramSwap.enable = true;

  networking.networkmanager.enable = true;

  time.timeZone = "Europe/Ljubljana";

  i18n.defaultLocale = "en_US.UTF-8";
  i18n.extraLocaleSettings = {
    LC_ADDRESS = "sl_SI.UTF-8";
    LC_IDENTIFICATION = "sl_SI.UTF-8";
    LC_MEASUREMENT = "sl_SI.UTF-8";
    LC_MONETARY = "sl_SI.UTF-8";
    LC_NAME = "sl_SI.UTF-8";
    LC_NUMERIC = "sl_SI.UTF-8";
    LC_PAPER = "sl_SI.UTF-8";
    LC_TELEPHONE = "sl_SI.UTF-8";
    LC_TIME = "sl_SI.UTF-8";
  };

  users.users.andrejf = {
    isNormalUser = true;
    uid = 1000;
    description = "Andrej Fidel";
    extraGroups = [
      "wheel"
      "networkmanager"
      "docker"
      "video"
      "i2c"
    ];
    shell = pkgs.zsh;
    # Change with `passwd` after first login.
    initialPassword = "changeme";
  };

  programs.zsh = {
    enable = true;
    # ~/.zshrc runs compinit itself.
    enableGlobalCompInit = false;
  };

  programs.git = {
    enable = true;
    config.user.name = "Andrej Fidel";
  };

  services.openssh.enable = true;

  virtualisation.docker.enable = true;

  # Mason downloads prebuilt, dynamically linked LSPs/formatters.
  programs.nix-ld.enable = true;

  system.stateVersion = "26.05";
}
