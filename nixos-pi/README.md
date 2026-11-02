# NixOS on the Raspberry Pi 4

Standalone flake, unrelated to `../nixos`. The SD card is read-only, and all
state lives on the external SSD.

| File               | What                                                                 |
| ------------------ | -------------------------------------------------------------------- |
| `configuration.nix`| Host basics: user, SSH, Docker, network (ethernet DHCP, `pi.local`)   |
| `hardware.nix`     | Pi 4: aarch64, mainline kernel, USB/SD initrd modules, firmware files |
| `sd-card.nix`      | Read-only SD card, tmpfs `/`, first-boot handling, `sd-rw`/`sd-ro`    |
| `disk-layout.nix`  | disko layout of the SSD (btrfs subvolumes + 32G swapfile)             |
| `storage.nix`      | SSD layout + monthly btrfs scrub                                      |
| `test.nix`         | x86_64 VM test of the whole boot layout                               |

## Layout

SD card (`mmcblk0`), written as the image built by this flake:

| Partition    | Mounted at       | Contents                               |
| ------------ | ---------------- | -------------------------------------- |
| `FIRMWARE`   | not mounted      | Pi firmware, `config.txt`, U-Boot      |
| `NIXOS_SD`   | `/sd` (**ro**)   | `/nix` and `/boot` (bind mounts)       |

`/` is a tmpfs, so anything written outside the SSD is gone after a reboot.

SSD (one GPT partition, btrfs labelled `pi-storage`, `compress=zstd,noatime`):

| Subvolume | Mounted at        |
| --------- | ----------------- |
| `/var`    | `/var`            |
| `/home`   | `/home`           |
| `/docker` | `/var/lib/docker` |
| `/data`   | `/data`           |
| `/swap`   | `/swap` (32G `swapfile`) |

`/var` and `/home` are mounted in the initrd, so the Pi **won't boot without the SSD**.

## Install

### 1. Let this machine build aarch64 (one time)

Everything heavy comes from cache.nixos.org, but the system's own small
derivations (initrd, units, the image) have to run as aarch64. On Arch:

```sh
sudo pacman -S qemu-user-static qemu-user-static-binfmt
echo 'extra-platforms = aarch64-linux' | sudo tee -a /etc/nix/nix.conf
sudo systemctl restart nix-daemon
```

### 2. Build the SD image

```sh
nix build .#sd-image
```

### 3. Flash the SD card

```sh
zstd -dc result/sd-image/*.img.zst \
  | sudo dd of=/dev/disk/by-id/mmc-MSSD0_0x0000777d bs=4M conv=fsync status=progress
```

### 4. Format the SSD

**Wipes the SSD** (`/dev/disk/by-id/usb-Samsung_SSD_980_PRO_1TB_01326800019B-0:0`,
see `disk-layout.nix`). It lists the disk and asks for `yes` first. It also runs
`umount -R /mnt`.

```sh
sudo nix run .#format-ssd
```

### 5. Boot

Plug both into the Pi (SSD on a blue USB 3 port), connect ethernet, power on.
The first boot makes the card writable once to grow the partition and register
the Nix store, then switches it back to read-only. After that:

```sh
ssh andrejf@pi.local
```

`sudo` doesn't need a password. For console logins, set a password stored on the SSD:

```sh
mkpasswd | sudo install -Dm600 /dev/stdin /var/lib/secrets/andrejf.passwd
```

It takes effect on the next rebuild or reboot.

## Changing the system

Anything that writes to the store (rebuilds, `nix-collect-garbage`, `nix
profile`) needs the card writable:

```sh
sudo sd-rw        # remount the SD card read-write
sudo sd-ro        # back to read-only
```

The Nix daemon only runs while the card is writable, so every `nix` command
(including `nix run` and `nix shell`) fails with "Connection refused" until
`sd-rw` has started it.

Rebuild on the Pi (copy or clone this directory to the Pi first). `pi-rebuild`
wraps `nixos-rebuild` with `sd-rw`/`sd-ro`:

```sh
make rebuild    # = sudo pi-rebuild switch --flake .#pi
```

Or build here (needs step 1) and push it to the Pi:

```sh
ssh pi.local sudo sd-rw
nix run nixpkgs#nixos-rebuild -- switch --flake .#pi --target-host andrejf@pi.local --sudo
ssh pi.local sudo sd-ro
```

## Testing

Boots the real sd-image and disko layout in a VM (x86_64, without `hardware.nix`):
first boot, read-only checks, persistence across a reboot, Docker, swap,
`sd-rw`/`sd-ro`.

```sh
nix build .#checks.x86_64-linux.vm-test -L
```
