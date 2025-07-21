{ config, pkgs, inputs, ... }:

{
  home-manager.users.codecannon = rec {
    home.stateVersion = "25.05"; # Or "23.11", etc.
    home.username = "codecannon";
    home.homeDirectory = "/home/codecannon";

    home.packages = with pkgs; [
      catppuccin-gtk
      catppuccin-papirus-folders
      catppuccin-cursors.mochaDark
    ];

    gtk = {
      enable = true;
      theme = {
	name = "Catppuccin-Mocha-Standard-Blue-Dark";
	package = pkgs.catppuccin-gtk.override {
	  accents = [ "blue" ];
	  variant = "mocha";
	};
      };
      iconTheme = {
	name = "Papirus-Dark";
	package = pkgs.catppuccin-papirus-folders;
      };
      cursorTheme = {
	name = "Catppuccin-Mocha-Dark";
	package = pkgs.catppuccin-cursors.mochaDark;
      };
    };

    qt = {
      enable = true;
      platformTheme = "gtk"; # Tells Qt apps to use the GTK theme
      style = {
	name = "kvantum"; # Use Kvantum for better Qt theming
	package = pkgs.catppuccin-kvantum;
      };
    };

    xdg.configFile."Kvantum/kvantum.kvconfig".text = ''
      [General]
      theme=Catppuccin-Mocha
    '';

    xdg.configFile."Kvantum/Catppuccin-Mocha/Catppuccin-Mocha.kvconfig".source =
      (pkgs.catppuccin-kvantum.override { variant = "mocha"; }).out
      + "/share/Kvantum/Catppuccin-Mocha/Catppuccin-Mocha.kvconfig";

    xdg.portal = {
      enable = true;
      extraPortals = with pkgs; [
	xdg-desktop-portal-gtk
      ];
    };

    wayland.windowManager.hyprland.settings = {
      general = {
	"col.active_border" = "rgb(89b4fa)"; # Catppuccin Blue
	"col.inactive_border" = "rgb(494d64)"; # Catppuccin Surface0
	"border_size" = 1;
	"gaps_in" = 4;
	"gaps_out" = 8;
      };
    };

    programs.neovim = {
      enable = true;
      defaultEditor = true;
      vimAlias = true;
      vimdiffAlias = true;
      withNodeJs = true;

      # This injects dependencies into Neovim's environment.
      # It makes fzflib.so and other tools available to Telescope.
      extraPackages = with pkgs; [
	fzf
	ripgrep
	fd
	gcc
	gnumake
	cmake
	stdenv.cc
        unzip
      ];
    };
  };

  programs.git.config = {
    user.name = "codecannon-server";
    user.email = "server@codecannon.dev";
  };
}
