# My dotfiles

## System setup

### 1. Install linux

Use the Arch installation guide as reference (https://wiki.archlinux.org/title/installation_guide)

1. Establish an internet connection
2. Install ansible
3. Mount partitions (mount on `/mnt`)
4. Run bootstrap ansible playbook `ansible-playbook bootstrap.yml`
5. Chroot into arch installation `arch-chroot /mnt`
6. Run laptop/workstation bootstrap playbook `ansible-playbook laptop-bootstrap.yml`
7. Run passwd to set the root password

### 2. Configure linux

When configuring a new instance of Arch while `arch-chroot`ed run:
```
ansible-playbook --ask-vault-pass system-setup.yml
```

When setting up laptop also run:
```
ansible-playbook --ask-vault-pass laptop-setup.yml
```

When setting up workstation also run:
```
ansible-playbook --ask-vault-pass workstation-setup.yml
```

### 3. Configure mkinitcpio for nvidia driver

1. Remove kms from the `HOOKS` array in `/etc/mkinitcpio.conf`
2. Regenerate the initramfs (`mkinitcpio -p linux`)

This will prevent the initramfs from containing the nouveau module making sure the kernel cannot load it during early boot.

### 4. Reboot



Networkmanager not in pacstrap.
User password not working.
Vim not in pacstrap.
User not in sudo.
Enabling docker doesn't work in chroot because systemd is not running.
Locale not working (need to update locale.gen then run locale-gen)
Bootloader config has to be regenerated
Owner of config files is root instead of andrejf
i3status is not installed
NetworkManager service needs to be enabled by default
Missing background
Missing sddm theme
Missing compositor
Ripgrep not installed correctly
Consider not running setup scripts in chroot (so systemd can be running when packages are installed)
Missing rustup installation
Missing rust analyzer
Missing i3lock
Missing docker compose
Timezone is not set
Time doesn't update automatically
