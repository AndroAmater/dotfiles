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
