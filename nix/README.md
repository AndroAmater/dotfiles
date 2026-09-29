# NixOS

Flake at the repo root (`flake.nix`), NixOS unstable, Hyprland + quickshell,
btrfs via [disko](https://github.com/nix-community/disko).

The old `nixos/` directory is the separate k8s server config and is not
used here.

```
flake.nix
nix/
  hosts/andrej-laptop/   ASUS laptop (AMD iGPU + NVIDIA PRIME offload)
  hosts/vm/              QEMU test VM (same modules, no laptop hardware)
  modules/common.nix     boot, nix, locale, user, docker, nix-ld
  modules/disko-btrfs.nix  ESP + btrfs subvolumes (@ @home @nix @log @snapshots)
  modules/desktop.nix    Hyprland, GDM, pipewire, bluetooth, fonts, GUI apps
  modules/packages.nix   CLI / dev tools used by the dotfiles
  modules/fhs-compat.nix symlinks for Arch paths the dotfiles hardcode
  home/                  home-manager: links dotfiles like link.sh does
  vm-runner.nix          `nix run .#vm`
```

Dotfiles are linked with out-of-store symlinks to `~/.config/dotfiles`, so
the checkout must live there, and edits apply without a rebuild.

New files must be `git add`ed before nix can see them (flakes only read
tracked files).

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
- On first boot the flake source is copied to `~/.config/dotfiles` in the VM.
  To try config changes inside the VM:
  `sudo nixos-rebuild switch --flake ~/.config/dotfiles#vm`
- State (disk overlay, EFI vars) is kept in `~/.local/share/nixos-vm`.
  Delete that directory to start over from a freshly built image.
- `NIXOS_VM_MEMORY` (default `8G`) and `NIXOS_VM_CORES` (default `4`)
  resize the VM. Extra arguments are passed to QEMU.

Build only the image (`result/main.qcow2`, usable in virt-manager with UEFI):

```sh
nix build .#vm-image
```

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
git clone git@github.com:androamater/dotfiles ~/.config/dotfiles
sudo nixos-rebuild switch --flake ~/.config/dotfiles#andrej-laptop
```

## Not carried over (yet)

- `clipboard-sync` (AUR, used by the EVE clipboard fix): not in nixpkgs.
  `hypr/clipsync.sh` still works.
- i3, i3status, rofi, waybar: superseded by Hyprland/quickshell.
- `laptop/ssh` (ansible-vault) and `nixos/secrets`: needs a secrets
  setup (e.g. sops-nix) — to do.
- Everything else from the pacman package list.
