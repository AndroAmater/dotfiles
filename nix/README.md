# NixOS

Flake at the repo root (`flake.nix`), NixOS unstable, Hyprland + quickshell,
btrfs via [disko](https://github.com/nix-community/disko).

The old `nixos/` directory is the separate k8s server config and is not
used here.

```
flake.nix
nix/
  hosts/andrej-laptop/   ASUS laptop (AMD iGPU + NVIDIA PRIME offload)
  hosts/andrej-external/ the laptop config on the external USB SSD
  hosts/vm/              QEMU test VM (same modules, no laptop hardware)
  modules/common.nix     boot, nix, locale, user, docker, nix-ld
  modules/disko-btrfs.nix  ESP + btrfs subvolumes (@ @home @nix @log @snapshots)
  modules/desktop.nix    Hyprland, GDM, pipewire, bluetooth, fonts, GUI apps
  modules/packages.nix   CLI / dev tools used by the dotfiles
  modules/services.nix   tailscale, cron, mariadb, nginx
  modules/fhs-compat.nix symlinks for Arch paths the dotfiles hardcode
  modules/dotfiles.nix   provisions the ~/.config/dotfiles checkout
  home/                  home-manager: links dotfiles like link.sh does
  vm-runner.nix          `nix run .#vm`
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

## Test VM

On any machine with Nix and KVM. Flakes must be enabled once:

```sh
mkdir -p ~/.config/nix
echo 'experimental-features = nix-command flakes' >> ~/.config/nix/nix.conf
```

Then:

```sh
nix run .#vm            # GTK window, virgl 3D acceleration
nix run .#vm -- --no-gl # software rendering, if GL fails on the host
```

- Login: `andrejf` / `changeme`
- SSH: `ssh -p 2222 andrejf@localhost`
- The host's `~/.config/dotfiles` is shared into the VM at the same path
  (read-write, override with `NIXOS_VM_DOTFILES`). Edit on the host and the
  VM sees it immediately; edits in the VM land in your host checkout. To
  apply NixOS config changes in the VM:
  `sudo nixos-rebuild switch --flake ~/.config/dotfiles#vm`
- Apps that watch their config (Hyprland, quickshell) don't notice
  host-side edits through the share; reload them (Super+Shift+C for
  Hyprland) or make the edit inside the VM.
- State (disk overlay, EFI vars) is kept in `~/.local/share/nixos-vm`.
  Delete that directory to start over from a freshly built image.
- `NIXOS_VM_MEMORY` (default `8G`) and `NIXOS_VM_CORES` (default `4`)
  resize the VM. Extra arguments are passed to QEMU.

Build only the image (`result/main.qcow2`, usable in virt-manager with UEFI):

```sh
nix build .#vm-image
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

# Partition + format + mount at /mnt (DESTRUCTIVE)
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

`disko` wipes `nvme1n1` (Samsung 980 PRO, the Arch disk).

**Windows' bootloader is on that disk's ESP** (`/boot/EFI/Microsoft`),
even though Windows itself is on `nvme0n1`. Back it up first or Windows
will not boot:

```sh
# on Arch, before anything else
sudo cp -a /boot/EFI/Microsoft ~/efi-microsoft-backup
# then copy ~/efi-microsoft-backup to a USB stick
```

Push the nix config to GitHub first: the installer clones it from there,
and the new system's `~/.config/dotfiles` is cloned from there on first
boot.

From the NixOS installer ISO:

```sh
sudo -i
nmcli device wifi connect <ssid> password <pw>   # if not on ethernet
git clone https://github.com/androamater/dotfiles /tmp/dotfiles

# Partition + format + mount at /mnt (DESTRUCTIVE)
nix --experimental-features 'nix-command flakes' run github:nix-community/disko/latest -- \
  --mode destroy,format,mount --flake /tmp/dotfiles#andrej-laptop

# Restore the Windows bootloader onto the new ESP
cp -a /path/to/usb/efi-microsoft-backup /mnt/boot/EFI/Microsoft

nixos-install --flake /tmp/dotfiles#andrej-laptop
reboot
```

After first login (`andrejf` / `changeme`):

```sh
passwd
# ~/.config/dotfiles was cloned over https; switch to ssh for pushing
git -C ~/.config/dotfiles remote set-url origin git@github.com:androamater/dotfiles
```

## Not carried over (yet)

- `clipboard-sync` (AUR, used by the EVE clipboard fix): not in nixpkgs.
  `hypr/clipsync.sh` still works.
- i3, i3status, rofi, waybar: superseded by Hyprland/quickshell.
- `laptop/ssh` (ansible-vault) and `nixos/secrets`: needs a secrets
  setup (e.g. sops-nix) — to do.
- `pulseaudio-control` (AUR): not in nixpkgs.
- Font Awesome 6 Pro (quickshell's "Font Awesome 6 Sharp"): licensed, so
  not in the repo. Copy `~/.local/share/fonts/fontawesome-pro-6.5.2-desktop`
  over by hand.
