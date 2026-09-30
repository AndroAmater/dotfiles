# Hyprland + quickshell desktop, as configured in hypr/ and quickshell/.
{ pkgs, ... }:

{
  programs.hyprland = {
    enable = true;
    xwayland.enable = true;
  };

  services.displayManager.gdm.enable = true;
  services.displayManager.defaultSession = "hyprland";

  environment.sessionVariables.NIXOS_OZONE_WL = "1";

  # Audio: quickshell's Pipewire service, pactl volume binds.
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    pulse.enable = true;
    jack.enable = true;
  };

  # quickshell Bluetooth / UPower / Networking widgets.
  hardware.bluetooth.enable = true;
  services.upower.enable = true;

  # Displays widget drives external monitor brightness via ddcutil.
  hardware.i2c.enable = true;

  security.polkit.enable = true;
  security.pam.services.swaylock = { };

  programs.dconf.enable = true;

  environment.systemPackages = with pkgs; [
    quickshell
    kitty
    mako
    swaybg
    swayidle
    swaylock
    polkit_gnome
    grim
    slurp
    wl-clipboard
    # hypr/clipsync.sh (X11 <-> Wayland clipboard bridge for Wine)
    clipnotify
    xclip
    brightnessctl
    ddcutil
    pulseaudio # pactl
    pavucontrol
    networkmanagerapplet # nm-connection-editor
    btop
    xset
    bluetui
    gnome-control-center
    chromium
    firefox
    google-chrome
    code-cursor
    vscode
    jetbrains-toolbox
    nautilus
    vlc
    mpv
    feh
    obs-studio
    handbrake
    inkscape
    drawio
    libreoffice
    kdePackages.okular
    obsidian
    discord
    transmission_4-gtk
  ];

  programs.steam.enable = true;

  fonts.packages = with pkgs; [
    nerd-fonts.jetbrains-mono
    jetbrains-mono
    noto-fonts
    noto-fonts-color-emoji
    font-awesome
    freefont_ttf
  ];
}
