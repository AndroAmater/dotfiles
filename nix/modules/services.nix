{ pkgs, ... }:

{
  services.tailscale.enable = true;

  # NixOS ships vixie-cron; `crontab -e` works the same as with cronie.
  services.cron.enable = true;

  services.mysql = {
    enable = true;
    package = pkgs.mariadb;
  };

  # Local only: port 80 stays closed in the firewall.
  services.nginx.enable = true;
}
