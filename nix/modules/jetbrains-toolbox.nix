# JetBrains Toolbox.
#
# The locked nixpkgs pins 3.8.1, which JetBrains has removed from its CDN.
# Mirrors nixpkgs' Linux FHS wrapper with a version that still downloads.
{ pkgs, ... }:

let
  version = "3.9.1.89198";
  src = pkgs.fetchzip {
    url = "https://download.jetbrains.com/toolbox/jetbrains-toolbox-${version}.tar.gz";
    hash = "sha256-21MTezmZpvxgilxdkFCciUBG6gYi7CYFCYmz2jGcfP4=";
  };

  package = pkgs.buildFHSEnv {
    pname = "jetbrains-toolbox";
    inherit version;
    inherit (pkgs.jetbrains-toolbox) meta;
    multiPkgs =
      fhsPkgs:
      with fhsPkgs;
      [
        icu
        libappindicator
      ]
      ++ pkgs.appimageTools.defaultFhsEnvArgs.multiPkgs fhsPkgs;
    runScript = "${src}/bin/jetbrains-toolbox --update-failed";

    extraInstallCommands = ''
      install -Dm0644 ${src}/bin/jetbrains-toolbox.desktop -t $out/share/applications
      install -Dm0644 ${src}/bin/toolbox-tray-color.png $out/share/icons/hicolor/32x32/apps/jetbrains-toolbox.png
    '';
  };
in
{
  environment.systemPackages = [ package ];
}
