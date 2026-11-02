# CLI and dev tooling referenced by .zshrc, nvim/, lazygit/, k9s/ and
# system-setup.yml.
{ pkgs, ... }:

let
  # The locked nixpkgs still ships v1. Use the official v2 binary without
  # upgrading the entire desktop's nixpkgs input just to update this CLI.
  opencodeV2 = pkgs.stdenvNoCC.mkDerivation (finalAttrs: {
    pname = "opencode";
    version = "2.2.5";

    src = pkgs.fetchurl {
      url = "https://registry.npmjs.org/@opencode/cli-linux-x64/-/cli-linux-x64-${finalAttrs.version}.tgz";
      hash = "sha256-kmkO7gemgNPLdgygK6Q4eN6eqxtOXV366HlVGMU2KPQ=";
    };

    nativeBuildInputs = with pkgs; [
      autoPatchelfHook
      makeBinaryWrapper
    ];
    buildInputs = [ pkgs.stdenv.cc.cc.lib ];

    dontBuild = true;
    dontStrip = true; # Preserve Bun's embedded application.

    installPhase = ''
      runHook preInstall

      install -Dm755 bin/opencode $out/bin/opencode
      wrapProgram $out/bin/opencode \
        --set OPENCODE_DISABLE_AUTOUPDATE true \
        --suffix PATH : ${pkgs.lib.makeBinPath [ pkgs.ripgrep ]} \
        --prefix LD_LIBRARY_PATH : ${
          pkgs.lib.makeLibraryPath [
            pkgs.stdenv.cc.cc.lib
            pkgs.wayland
          ]
        }

      runHook postInstall
    '';

    doInstallCheck = true;
    nativeInstallCheckInputs = with pkgs; [
      versionCheckHook
      writableTmpDirAsHomeHook
    ];
    versionCheckKeepEnvironment = [ "HOME" ];
    versionCheckProgramArg = "--version";

    meta = {
      description = "OpenCode v2 AI coding agent";
      homepage = "https://opencode.ai/v2/docs";
      license = pkgs.lib.licenses.mit;
      sourceProvenance = [ pkgs.lib.sourceTypes.binaryNativeCode ];
      platforms = [ "x86_64-linux" ];
      mainProgram = "opencode";
    };
  });
in
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
    dive
    kubectl
    kubectx
    kubernetes-helm
    k9s
    argocd
    doctl
    vault
    # nix/first-boot.sh decrypts the secrets archive
    gnupg

    # Misc CLI
    vim
    tree
    yq
    imagemagick
    gh
    pnpm
    uv
    rust-analyzer
    bazelisk
    # The AUR bazelisk-bin also provided `bazel`.
    (writeShellScriptBin "bazel" ''exec ${bazelisk}/bin/bazelisk "$@"'')
    playwright-test

    # AI coding agents
    opencodeV2
    claude-code
  ];
}
