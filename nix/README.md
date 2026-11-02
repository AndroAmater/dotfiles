# NixOS

Flake at the repo root (`flake.nix`), NixOS unstable, Hyprland + quickshell,
LUKS2-encrypted btrfs via [disko](https://github.com/nix-community/disko).

The old `nixos/` directory is the separate k8s server config and is not
used here.

```
flake.nix
nix/
  hosts/andrej-laptop/   ASUS laptop (AMD iGPU + NVIDIA PRIME offload)
  hosts/andrej-external/ the laptop config on the external USB SSD
  modules/common.nix     boot, nix, locale, user, docker, nix-ld
  modules/disko-btrfs.nix  ESP + LUKS2 + btrfs (@ @home @nix @log @home-snapshots),
                         snapper for /home, monthly scrub
  modules/desktop.nix    Hyprland, GDM, pipewire, bluetooth, fonts, GUI apps
  modules/packages.nix   CLI / dev tools used by the dotfiles
  modules/services.nix   tailscale, cron, mariadb, nginx
  modules/fhs-compat.nix symlinks for Arch paths the dotfiles hardcode
  modules/dotfiles.nix   provisions the ~/.config/dotfiles checkout
  modules/hyprwhspr.nix  speech-to-text (upstream flake + ElevenLabs backend)
  home/                  home-manager: links dotfiles like link.sh does
```

## Working on the config

On every host, the dotfiles are symlinked from a live git checkout at
`~/.config/dotfiles` (never copied into the nix store). On first boot, if
that checkout is missing, it is cloned from GitHub (or, when offline,
copied from the flake the system was built from).

That checkout is also the flake, so nothing needs committing to test:

- **Dotfiles** (`hypr/`, `nvim/`, `.zshrc`, …): edit, and the change is
  live. Reload the app as usual (e.g. `hyprctl reload`).
- **NixOS config** (`flake.nix`, `nix/`): edit, then
  `sudo nixos-rebuild switch --flake ~/.config/dotfiles`
  (the hostname picks the config). Uncommitted changes are built; only
  brand-new files need a `git add` (no commit), since flakes ignore
  untracked files.
  - `nixos-rebuild test` activates without adding a boot entry.
  - A bad generation can be undone with
    `sudo nixos-rebuild switch --rollback`, or by picking an older entry
    in the boot menu.

Commit and push once you're happy with a change.

### AI coding agents and icon fonts

`nix/modules/packages.nix` installs Claude Code (`claude`) and pins the
official OpenCode v2 binary (`opencode`, currently 2.2.5). Both are managed
by Nix; update them through this config rather than their self-updaters.
For an OpenCode update, check
<https://opencode.ai/update/api/latest/cli/npm>, update `opencodeV2.version`,
and obtain the matching archive hash with:

```sh
nix store prefetch-file --json \
  https://registry.npmjs.org/@opencode/cli-linux-x64/-/cli-linux-x64-<version>.tgz
```

Kitty uses Font Awesome 7 Pro Solid; quickshell uses Font Awesome 7 Sharp
Solid. Both use Font Awesome 7 Brands for brand icons. Install the licensed
Desktop OTFs locally (currently Font Awesome Pro 7.3.1):

```sh
mkdir -p ~/.local/share/fonts
unzip -n ~/Downloads/fontawesome-pro-7.3.1-desktop.zip \
  'fontawesome-pro-7.3.1-desktop/otfs/*.otf' -d ~/.local/share/fonts
fc-cache -f ~/.local/share/fonts
```

Kitty also uses JetBrainsMono Nerd Font and Symbols Nerd Font Mono for
text, Powerline, devicons and Material Design symbols, installed by
`nix/modules/desktop.nix`. After installing fonts, reload Kitty's config
and restart quickshell (or log out and back in).

## Disk encryption

Everything except the ESP (`/boot`: kernel, initrd, systemd-boot) is on a
LUKS2 volume (`cryptroot`). disko asks for the passphrase while formatting,
and the initrd asks for it on every boot. It is not stored anywhere, so
don't lose it: there is no recovery key. To add a second passphrase later:

```sh
sudo cryptsetup luksAddKey /dev/disk/by-partlabel/disk-main-root
```

## Snapshots of /home

snapper snapshots `/home` every hour and keeps 24 hourly, 7 daily and 4
weekly snapshots. They are on the same disk, so they are not a backup.
`~/.cache` is a separate subvolume and is left out.

```sh
snapper -c home list                       # what's there
ls /home/.snapshots/<n>/snapshot/andrejf   # browse one, copy files back
snapper -c home status <n>..0              # what changed since snapshot <n>
snapper -c home undochange <n>..0 <file>   # restore a file in place
```

## Installing on the external SSD

`andrej-external` is the laptop config on the external USB SSD (Samsung
980 PRO in the Ugreen enclosure). It leaves the internal disks and the
firmware boot entries alone. `disko` wipes the external SSD.

Push the branch first; the installer clones it. From the NixOS installer
ISO (booted in UEFI mode, Secure Boot off, external SSD plugged in):

```sh
sudo -i
nmcli device wifi connect <ssid> password <pw>   # if not on ethernet
export NIX_CONFIG='experimental-features = nix-command flakes'
git clone --branch nix https://github.com/androamater/dotfiles /tmp/dotfiles
cd /tmp/dotfiles

# Must be the 931.5G USB Samsung SSD
lsblk -o NAME,SIZE,MODEL,TRAN,FSTYPE,LABEL,MOUNTPOINTS \
  /dev/disk/by-id/usb-Samsung_SSD_980_PRO_1TB_01326800019B-0:0

# Partition + encrypt + format + mount at /mnt (DESTRUCTIVE).
# Prompts for the new LUKS passphrase.
nix run --inputs-from . disko -- \
  --mode destroy,format,mount --flake .#andrej-external

nixos-install --flake .#andrej-external

# First boot would clone the default branch; use this checkout instead
mkdir -p /mnt/home/andrejf/.config
cp -a /tmp/dotfiles /mnt/home/andrejf/.config/dotfiles
chown -R 1000:100 /mnt/home/andrejf/.config

umount -R /mnt
reboot
```

Pick the USB SSD from the firmware's one-time boot menu. Unplug it (or
pick the internal disk) to get back to Arch. Rebuild with
`sudo nixos-rebuild switch --flake ~/.config/dotfiles#andrej-external`.

## Installing on the laptop

`disko` wipes `nvme1n1` (Samsung 980 PRO, the Arch disk). Commit and push
first: the installer clones the repo from GitHub.

### Backup drive

`nix/install.sh` reads the backup USB drive (NTFS, UUID `F09CB8959CB857B4`;
override with `BACKUP_UUID=...`). Prepare it on Arch, before anything else:

- **`efi-microsoft-backup/`**: Windows' bootloader. It lives on the Arch
  disk's ESP even though Windows is on `nvme0n1`; without it Windows won't
  boot. Required; the script stops before wiping if it's missing.
- **`secrets-*.tar.gz.gpg`**: an encrypted archive of everything to restore
  into `~` (ssh keys, logins, Wi-Fi profiles…). Optional.

```sh
D=/run/media/andrejf/F09CB8959CB857B4
sudo cp -r /boot/EFI/Microsoft "$D/efi-microsoft-backup"

cd ~
sudo tar czf /tmp/nm-connections.tgz -C / etc/NetworkManager/system-connections
sudo chown andrejf /tmp/nm-connections.tgz
tar czf - \
  .ssh .kube/config .docker/config.json .cloudflared .vault-token \
  .config/gh/hosts.yml .config/doctl .config/argocd .config/turso \
  .config/dotfiles/opencode/.env .config/dotfiles/opencode/secrets .config/dotfiles/opencode/service.json \
  .config/JetBrains .local/share/fonts \
  -C /tmp nm-connections.tgz \
  | gpg --symmetric --cipher-algo AES256 -o "$D/secrets-$(date +%F).tar.gz.gpg"
```

### Install

Boot the NixOS installer ISO (UEFI mode, Secure Boot off), plug in the
backup drive, then:

```sh
sudo -i
nmcli device wifi connect <ssid> password <pw>   # if not on ethernet
git clone https://github.com/androamater/dotfiles /tmp/dotfiles
/tmp/dotfiles/nix/install.sh
reboot
```

`install.sh` checks the backup drive, shows the target disk and asks you to
type the host name, then: partitions, encrypts (asks for the new LUKS
passphrase), formats, restores the Windows bootloader, runs `nixos-install`
(asks for a root password), and copies the checkout and the secrets archive
into `/home/andrejf`.

### First boot

Unlock the disk, log in as `andrejf` / `changeme`, then:

```sh
~/.config/dotfiles/nix/first-boot.sh
```

It changes the password, restores the secrets archive (and the Wi-Fi
profiles, with sudo), asks for the ElevenLabs API key for hyprwhspr, and
switches the dotfiles remote to ssh. Windows shows up in the boot menu.

## Not carried over (yet)

- `clipboard-sync` (AUR, used by the EVE clipboard fix): not in nixpkgs.
  `hypr/clipsync.sh` still works.
- i3, i3status, rofi, waybar: superseded by Hyprland/quickshell.
- `laptop/ssh` (ansible-vault) and `nixos/secrets`: needs a secrets
  setup (e.g. sops-nix) — to do.
- `pulseaudio-control` (AUR): not in nixpkgs.
