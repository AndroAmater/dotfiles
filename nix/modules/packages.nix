# CLI and dev tooling referenced by .zshrc, nvim/, lazygit/, k9s/ and
# system-setup.yml.
{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    # Shell
    oh-my-posh
    tmux
    fzf
    eza
    # .zshrc aliases still call `exa`, which was renamed to eza.
    (writeShellScriptBin "exa" ''exec ${eza}/bin/eza "$@"'')
    bat
    ripgrep
    fd
    jq
    curl
    wget
    rsync
    zip
    unzip
    gnutar
    nmap
    bottom
    ffmpeg

    # Git
    git
    lazygit
    delta
    gitui

    # Neovim + what lazy.nvim, treesitter (main branch) and mason need
    neovim
    tree-sitter
    gcc
    gnumake
    python3
    stylua
    prettierd
    zig
    zls

    # Languages / runtimes
    nodejs
    yarn
    bun
    go
    rustup
    php
    phpPackages.composer

    # Containers / k8s
    docker-compose
    kubectl
    k9s

    opencode
  ];
}
