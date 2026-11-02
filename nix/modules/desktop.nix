# Hyprland + quickshell desktop, as configured in hypr/ and quickshell/.
{ pkgs, ... }:

{
  programs.hyprland = {
    enable = true;
    xwayland.enable = true;
  };

  services.displayManager.gdm.enable = true;
  services.displayManager.defaultSession = "hyprland";

  environment.sessionVariables = {
    NIXOS_OZONE_WL = "1";
    # Without a cursor theme Hyprland falls back to its built-in cursor.
    XCURSOR_THEME = "Adwaita";
    XCURSOR_SIZE = "24";
  };

  # Caps Lock and Right Alt act as Super, on every keyboard.
  services.keyd = {
    enable = true;
    keyboards.default = {
      ids = [ "*" ];
      settings.main = {
        capslock = "leftmeta";
        rightalt = "leftmeta";
      };
    };
  };

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
    adwaita-icon-theme # XCURSOR_THEME
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
    # quickshell's Theme.qml wants "Font Awesome 6 Brands" (v7 renamed
    # it). Its "Font Awesome 6 Sharp" is Pro-only: copy it into
    # ~/.local/share/fonts by hand.
    font-awesome_6
    freefont_ttf
  ];
}
