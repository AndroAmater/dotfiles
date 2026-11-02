#!/usr/bin/env bash
# Installs NixOS from the installer ISO. Run as root from a clone of this repo:
#
#   sudo -i
#   nmcli device wifi connect <ssid> password <pw>   # if not on ethernet
#   git clone https://github.com/androamater/dotfiles /tmp/dotfiles
#   /tmp/dotfiles/nix/install.sh [host]              # default: andrej-laptop
#
# With the backup USB drive plugged in (BACKUP_UUID, below), it:
#   1. checks the backup drive has what's needed, before touching any disk
#   2. wipes, encrypts (asks for the new LUKS passphrase), formats and mounts
#      the host's disk with disko
#   3. restores the Windows bootloader onto the new ESP (andrej-laptop only)
#   4. runs nixos-install (asks for a root password at the end)
#   5. copies this checkout and the encrypted secrets archive into
#      /home/andrejf, for nix/first-boot.sh
set -euo pipefail

HOST="${1:-andrej-laptop}"
# The SanDisk USB SSD (NTFS) holding efi-microsoft-backup/ and
# secrets-*.tar.gz.gpg. Override for a different drive.
BACKUP_UUID="${BACKUP_UUID:-F09CB8959CB857B4}"
BACKUP=/run/install-backup
USER_NAME=andrejf
USER_HOME="/mnt/home/$USER_NAME"

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export NIX_CONFIG="experimental-features = nix-command flakes"

die() {
  echo "error: $*" >&2
  exit 1
}

[ "$(id -u)" -eq 0 ] || die "run as root (sudo -i)"
[ -d /sys/firmware/efi ] || die "not booted in UEFI mode"

echo "==> Evaluating $HOST"
disk="$(nix eval --raw "$REPO#nixosConfigurations.$HOST.config.disko.devices.disk.main.device")"
[ -e "$disk" ] || die "target disk $disk not found"

echo "==> Mounting the backup drive"
backup_dev="/dev/disk/by-uuid/$BACKUP_UUID"
[ -e "$backup_dev" ] || die "backup drive $backup_dev not found (plug it in, or set BACKUP_UUID)"
mkdir -p "$BACKUP"
if ! mountpoint -q "$BACKUP"; then
  mount -o ro "$backup_dev" "$BACKUP" || mount -t ntfs3 -o ro "$backup_dev" "$BACKUP"
fi
trap 'umount "$BACKUP" 2>/dev/null || true' EXIT

restore_efi=false
if [ "$HOST" = andrej-laptop ]; then
  [ -f "$BACKUP/efi-microsoft-backup/Boot/bootmgfw.efi" ] ||
    die "$BACKUP/efi-microsoft-backup/Boot/bootmgfw.efi missing: Windows would not boot"
  restore_efi=true
fi
secrets="$(ls -t "$BACKUP"/secrets-*.tar.gz.gpg 2>/dev/null | head -1 || true)"
[ -n "$secrets" ] || echo "warning: no secrets-*.tar.gz.gpg on the backup drive; skipping it"

echo
lsblk -o NAME,SIZE,MODEL,TRAN,FSTYPE,LABEL "$disk"
echo
echo "This ERASES $disk ($(readlink -f "$disk")) and installs $HOST on it."
read -r -p "Type the host name ($HOST) to continue: " answer
[ "$answer" = "$HOST" ] || die "aborted"

echo "==> Partitioning, encrypting, formatting, mounting (enter the new LUKS passphrase)"
nix run --inputs-from "$REPO" disko -- \
  --mode destroy,format,mount --yes-wipe-all-disks --flake "$REPO#$HOST"

if $restore_efi; then
  echo "==> Restoring the Windows bootloader"
  mkdir -p /mnt/boot/EFI
  cp -r "$BACKUP/efi-microsoft-backup" /mnt/boot/EFI/Microsoft
fi

echo "==> Installing NixOS"
nixos-install --flake "$REPO#$HOST"

echo "==> Copying the dotfiles checkout and secrets archive to $USER_HOME"
# First boot would otherwise clone the repo again (modules/dotfiles.nix).
mkdir -p "$USER_HOME/.config"
if [ ! -e "$USER_HOME/.config/dotfiles" ]; then
  cp -a "$REPO" "$USER_HOME/.config/dotfiles"
fi
chown 1000:100 "$USER_HOME" "$USER_HOME/.config"
chown -R 1000:100 "$USER_HOME/.config/dotfiles"
chmod 700 "$USER_HOME"
if [ -n "$secrets" ]; then
  install -m 600 -o 1000 -g 100 "$secrets" "$USER_HOME/"
fi

echo
echo "Done. Reboot, unlock the disk, log in as $USER_NAME / changeme, then run:"
echo "  ~/.config/dotfiles/nix/first-boot.sh"
