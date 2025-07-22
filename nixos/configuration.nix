# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, inputs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
      inputs.sops-nix.nixosModules.sops
    ];

  nix.extraOptions = ''
    experimental-features = nix-command flakes
    '';

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  boot.kernel.sysctl = {
    "net.core.rmem_max" = 16000000;
    "net.core.wmem_max" = 16000000;
  };

  networking.hostName = "nixos"; # Define your hostname.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Enable networking
  networking.networkmanager.enable = true;

  # Set your time zone.
  time.timeZone = "Europe/Ljubljana";

  # Select internationalisation properties.
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

  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.codecannon = {
    isNormalUser = true;
    description = "codecannon";
    extraGroups = [ "networkmanager" "wheel" ];
    packages = with pkgs; [];
    shell = pkgs.zsh;
  };

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # Nvidia
  hardware.graphics.enable = true;
  services.xserver.videoDrivers = [ "nvidia" ];
  hardware.nvidia.open = true;

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    git
    neovim
    vim
    wget
    kitty
    wofi
    nautilus
    chromium
    waybar
    tmux
    oh-my-posh
    zsh
    zig
    fzf
    ripgrep
    fd
    font-awesome
    unzip
    htop
    cloudflared
    sops
    jq
    gnumake
  ];

  programs.nix-ld.enable = true;
  programs.nix-ld.libraries = with pkgs; [
    stylua
    fzf
  ];


  services.xserver = {
    enable = true;
    displayManager.gdm = {
      enable = true;
      wayland = true;
    };
  };


  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # List services that you want to enable:

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "25.05"; # Did you read the comment?

  fonts.packages = with pkgs; [ nerd-fonts.jetbrains-mono ];

  # Fix pixelated chrome
  environment.sessionVariables.NIXOS_OZONE_WL = "1";

  programs.hyprland = {
    enable = true;
    xwayland.enable = true;
  };

  programs = {
    lazygit.enable = true;
    hyprlock.enable = true;
    zsh.enable = true;
  };

  programs.git.config = {
    user.name = "codecannon-server";
    user.email = "server@codecannon.dev";
  };

  sops.age.keyFile = /root/.config/sops/age/keys.txt;

  sops.secrets.cloudflared-creds = {
    sopsFile = /secrets/cloudflared-creds.json;
    format = "json";
    key = "";
    owner        = "root";
    group        = "cloudflared";
    mode         = "440";
    restartUnits = [ "cloudflared-tunnel-d30a3a2b-6621-4f9b-9dc2-51e1058dfca4.service" ];
  };

  users.groups.cloudflared = { };

  services.cloudflared = {
    enable = true;
    tunnels = {
      "d30a3a2b-6621-4f9b-9dc2-51e1058dfca4" = {
        credentialsFile = config.sops.secrets.cloudflared-creds.path;
        warp-routing.enabled = false;
        default = "http_status:404";
        ingress = {
          "server.andrejfidel.com" = "ssh://localhost";
        };
      };
    };
  };

  services.openssh = {
    enable = true;
    ports = [ 22 ];
    settings = {
      PasswordAuthentication = false;
      PermitRootLogin = "yes";
    };
  };

  networking.firewall.allowedTCPPorts = [ 22 ];

  users.users.codecannon.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBVeZOkhHSfMO50UPdQrJcDKFVNH15gO6WJal+qQ9GN9 zephyrus-manjaro"
  ];
}
