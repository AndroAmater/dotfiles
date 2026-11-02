#!/usr/bin/env bash
# Run once as andrejf after the first login on a fresh install
# (nix/install.sh copies the secrets archive into ~):
#
#   ~/.config/dotfiles/nix/first-boot.sh [path/to/secrets-*.tar.gz.gpg]
#
# It changes the login password, restores the secrets archive into ~
# (ssh keys, cluster/CLI logins, opencode secrets, JetBrains, FontAwesome
# Pro, Wi-Fi profiles), and switches the dotfiles remote to ssh.
# Safe to re-run.
set -euo pipefail

DOTFILES="$HOME/.config/dotfiles"

die() {
  echo "error: $*" >&2
  exit 1
}

[ "$(id -u)" -ne 0 ] || die "run as your user, not root"

read -r -p "Change the login password now? [Y/n] " answer
if [[ ! "$answer" =~ ^[Nn] ]]; then
  passwd
fi

archive="${1:-$(ls -t "$HOME"/secrets-*.tar.gz.gpg 2>/dev/null | head -1 || true)}"
if [ -n "$archive" ]; then
  echo "==> Restoring $archive (enter the archive passphrase)"
  gpg --pinentry-mode loopback --decrypt "$archive" | tar xzf - -C "$HOME"

  if [ -d "$HOME/.ssh" ]; then
    chmod 700 "$HOME/.ssh"
    find "$HOME/.ssh" -type f ! -name '*.pub' -exec chmod 600 {} +
  fi

  fc-cache -f >/dev/null
else
  echo "warning: no ~/secrets-*.tar.gz.gpg found; skipping the secrets restore"
fi

# hyprwhspr's `setup` (which normally stores API keys) is disabled for Nix
# installs, so write its credential store directly: {"<provider>": "<key>"}.
creds="${XDG_DATA_HOME:-$HOME/.local/share}/hyprwhspr/credentials"
if ! jq -e '.elevenlabs // empty' "$creds" >/dev/null 2>&1; then
  read -r -s -p "ElevenLabs API key for hyprwhspr (empty to skip): " key
  echo
  if [ -n "$key" ]; then
    mkdir -p "$(dirname "$creds")"
    existing="$(cat "$creds" 2>/dev/null || echo '{}')"
    (
      umask 077
      jq --arg key "$key" '.elevenlabs = $key' <<<"$existing" >"$creds.tmp"
    )
    mv "$creds.tmp" "$creds"
    systemctl --user restart hyprwhspr || true
  fi
fi

echo "==> Switching the dotfiles remote to ssh"
git -C "$DOTFILES" remote set-url origin git@github.com:androamater/dotfiles

echo
echo "Done. Once everything works, delete the archive:"
echo "  rm $HOME/secrets-*.tar.gz.gpg"
