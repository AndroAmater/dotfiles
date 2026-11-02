# hyprwhspr speech-to-text (hypr/hyprland.conf: Super+D, Super+Alt+D;
# quickshell's Hyprwhspr widget). Uses upstream's NixOS module: the user
# service, uinput, and `input` group membership.
#
# Upstream's Nix package (beta) only ships the Whisper.cpp CPU backend and
# rejects the others, but hyprwhspr/config.json uses the ElevenLabs realtime
# backend. So: add its Python SDK (plus websocket-client for the other
# realtime providers) and allow `realtime-ws`.
#
# The ElevenLabs API key is not in the repo: run `hyprwhspr config edit` or
# restore ~/.local/share/hyprwhspr/credentials.
{ inputs, pkgs, ... }:

let
  upstream = inputs.hyprwhspr.packages.${pkgs.stdenv.hostPlatform.system}.hyprwhspr;

  python313 = pkgs.python313 // {
    withPackages =
      f:
      pkgs.python313.withPackages (
        ps:
        f ps
        ++ [
          ps.elevenlabs
          ps.websocket-client
        ]
      );
  };

  package = (upstream.override { inherit python313; }).overrideAttrs (old: {
    postPatch = (old.postPatch or "") + ''
      substituteInPlace lib/src/installation.py \
        --replace-fail "in ('cpu', 'pywhispercpp')" "in ('cpu', 'pywhispercpp', 'realtime-ws')"
    '';
  });
in
{
  imports = [ inputs.hyprwhspr.nixosModules.default ];

  services.hyprwhspr = {
    enable = true;
    users = [ "andrejf" ];
    inherit package;
  };
}
