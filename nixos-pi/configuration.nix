{ config, pkgs, ... }:

{
  networking.hostName = "pi";
  time.timeZone = "Europe/Ljubljana";
  i18n.defaultLocale = "en_US.UTF-8";

  # Ethernet with DHCP; reachable as pi.local.
  networking.useNetworkd = true;
  networking.useDHCP = true;
  services.resolved.enable = true;
  services.avahi = {
    enable = true;
    nssmdns4 = true;
    # Publishing the IPv6 link-local address made systemd-resolved clients sometimes resolve
    # pi.local to fe80::… only, which browsers can't connect to.
    ipv6 = false;
    publish = {
      enable = true;
      addresses = true;
    };
  };

  users.users.andrejf = {
    isNormalUser = true;
    extraGroups = [
      "wheel"
      "docker"
    ];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBVeZOkhHSfMO50UPdQrJcDKFVNH15gO6WJal+qQ9GN9 zephyrus-manjaro"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAYMH6eWNfVEJelhHbVCaS5gwYUMgh+AGJZYYFsikm9J andrej-server"
    ];
    # Optional, for console logins: `mkpasswd | sudo tee /var/lib/secrets/andrejf.passwd`.
    # Without it the account only accepts SSH keys.
    hashedPasswordFile = "/var/lib/secrets/andrejf.passwd";
  };
  security.sudo.wheelNeedsPassword = false;

  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
      PermitRootLogin = "no";
    };
  };

  virtualisation.docker = {
    enable = true;
    autoPrune.enable = true;
    daemon.settings.cgroup-parent = "docker.slice";
  };

  # Docker and its containers share docker.slice: at most 3 GB of RAM, the rest goes to swap.
  systemd.slices.docker.sliceConfig.MemoryMax = "3G";
  systemd.services.docker = {
    serviceConfig.Slice = "docker.slice";
    # Keep retrying a failed start instead of giving up after three attempts in a minute.
    startLimitIntervalSec = 0;
    serviceConfig.RestartSec = 10;
  };

  # Starts the connect-chat stack (deployed to ~/connect-chat by `make pi-images`) on every boot,
  # also after it was stopped by hand.
  systemd.services.connect-chat = {
    description = "connect-chat Docker Compose stack";
    wantedBy = [ "multi-user.target" ];
    # Wants, not Requires: a failed Docker start would otherwise cancel this unit for the whole boot.
    wants = [ "docker.service" ];
    after = [ "docker.service" ];
    unitConfig.RequiresMountsFor = [ "/home/andrejf/connect-chat" ];
    # A rebuild shouldn't (re)start the stack.
    restartIfChanged = false;
    # Retry until the stack is up, however long Docker or a container takes to come up.
    startLimitIntervalSec = 0;
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      Restart = "on-failure";
      RestartSec = 30;
      User = "andrejf";
      WorkingDirectory = "/home/andrejf/connect-chat";
      ExecStart = "${config.virtualisation.docker.package}/bin/docker compose -f docker-compose.nixos.yml --env-file .env.nixos up -d --remove-orphans";
    };
  };

  nix.settings = {
    experimental-features = [
      "nix-command"
      "flakes"
    ];
    # Lets nixos-rebuild --target-host copy closures from another machine.
    trusted-users = [ "@wheel" ];
  };

  environment.systemPackages = with pkgs; [
    git
    vim
    htop
    btop
    btrfs-progs
    smartmontools
    gnumake
  ];

  system.stateVersion = "26.05";
}
