# Boots the Pi's disk layout in an x86_64 VM: a real sd-image (tmpfs /,
# read-only /sd) plus an SSD formatted by the real disko config. Everything
# except hardware.nix is the Pi configuration.
{ pkgs, disko }:

let
  ssd =
    { lib, ... }:
    {
      imports = [
        disko.nixosModules.disko
        ./storage.nix
      ];
      disko.devices.disk.ssd.device = "/dev/disk/by-id/virtio-ssd";
      # Keep the test disk small.
      disko.devices.disk.ssd.content.partitions.storage.content.subvolumes."/swap".swap.swapfile.size =
        lib.mkForce "512M";
    };

  ssdDrive = {
    name = "ssd";
    file = "$SSD_IMAGE";
    deviceExtraOpts.serial = "ssd";
  };
in
pkgs.testers.runNixOSTest {
  name = "pi-readonly-sd";

  nodes.formatter = {
    imports = [ ssd ];
    disko.enableConfig = false;
    virtualisation.qemu.drives = [ ssdDrive ];
  };

  nodes.pi =
    { config, lib, ... }:
    {
      imports = [
        ssd
        ./sd-card.nix
        ./configuration.nix
      ];
      sdImage.populateFirmwareCommands = "";
      sdImage.compressImage = false;
      # qemu-vm.nix makes register-nix-paths also load the registration passed
      # as regInfo= on the kernel command line; that file must be on the card.
      sdImage.storePaths = [
        (pkgs.closureInfo { rootPaths = config.virtualisation.additionalPaths; })
      ];

      virtualisation = {
        diskImage = null;
        mountHostNixStore = false;
        useDefaultFilesystems = false;
        fileSystems = lib.mkForce { };
        memorySize = 2048;
        qemu.drives = [
          {
            name = "sd";
            file = "$SD_IMAGE";
            deviceExtraOpts.serial = "sd";
          }
          ssdDrive
        ];
      };
    };

  testScript =
    { nodes, ... }:
    let
      sdImage = "${nodes.pi.system.build.sdImage}/${nodes.pi.image.filePath}";
    in
    # python
    ''
      import os
      import subprocess
      import tempfile

      tmp = tempfile.mkdtemp()
      os.environ["SD_IMAGE"] = f"{tmp}/sd.qcow2"
      os.environ["SSD_IMAGE"] = f"{tmp}/ssd.qcow2"
      # The SD image is minimally sized; the bigger virtual card lets the first boot grow it.
      subprocess.run(["${pkgs.qemu}/bin/qemu-img", "create", "-f", "qcow2", "-b", "${sdImage}", "-F", "raw", os.environ["SD_IMAGE"], "8G"], check=True)
      subprocess.run(["${pkgs.qemu}/bin/qemu-img", "create", "-f", "qcow2", os.environ["SSD_IMAGE"], "4G"], check=True)

      def assert_no_failed_units():
          failed = pi.succeed("systemctl list-units --failed --no-legend --plain").strip()
          t.assertEqual(failed, "", f"failed units:\n{failed}")

      def assert_sd_read_only():
          for path in ["/sd", "/nix", "/boot"]:
              t.assertIn("ro", pi.succeed(f"findmnt -no OPTIONS {path}").split(","), path)
          pi.fail("touch /sd/x", "touch /nix/x", "touch /boot/x")

      with subtest("format the SSD with disko"):
          formatter.wait_for_unit("multi-user.target")
          formatter.succeed("${nodes.formatter.system.build.format}/bin/disko-format")
          formatter.shutdown()

      with subtest("first boot"):
          pi.wait_for_unit("multi-user.target")
          t.assertEqual(pi.succeed("findmnt -no FSTYPE /").strip(), "tmpfs")
          for unit in ["sd-first-boot", "register-nix-paths", "sd-first-boot-done"]:
              pi.succeed(f"systemctl is-active {unit}.service")
          assert_sd_read_only()
          size = int(pi.succeed("lsblk -bno SIZE /dev/disk/by-label/NIXOS_SD").strip())
          t.assertGreater(size, 7 * 1024**3, "SD partition was not grown")
          pi.succeed("test -L /nix/var/nix/profiles/system")
          pi.succeed("test ! -e /sd/nix-path-registration")
          assert_no_failed_units()

      with subtest("SSD layout"):
          for path in ["/var", "/home", "/var/lib/docker", "/data", "/swap"]:
              t.assertEqual(pi.succeed(f"findmnt -no FSTYPE {path}").strip(), "btrfs", path)
          pi.succeed("swapon --show=NAME --noheadings | grep -x /swap/swapfile")
          pi.wait_for_unit("docker.service")
          t.assertEqual(pi.succeed("docker info -f '{{.DockerRootDir}}'").strip(), "/var/lib/docker")

      with subtest("state persists across reboots"):
          hostKey = pi.succeed("ssh-keygen -lf /var/lib/ssh/ssh_host_ed25519_key.pub")
          for path in ["/var/lib/marker", "/home/andrejf/marker", "/data/marker", "/etc/not-persisted"]:
              pi.succeed(f"touch {path} 2>&1")
          pi.shutdown()
          pi.wait_for_unit("multi-user.target")
          t.assertEqual(pi.succeed("ssh-keygen -lf /var/lib/ssh/ssh_host_ed25519_key.pub"), hostKey)
          pi.succeed("test -e /var/lib/marker -a -e /home/andrejf/marker -a -e /data/marker")
          pi.succeed("test ! -e /etc/not-persisted")
          t.assertEqual(pi.succeed("cat /etc/machine-id").strip(), "603ecc66813b4d2987a1659e376bf01e")

      with subtest("later boots never write to the SD card"):
          t.assertIn("ConditionResult=no", pi.succeed("systemctl show -p ConditionResult sd-first-boot.service"))
          t.assertIn("ConditionResult=no", pi.succeed("systemctl show -p ConditionResult sd-first-boot-done.service"))
          assert_sd_read_only()
          assert_no_failed_units()

      with subtest("sd-rw / sd-ro"):
          pi.succeed("sd-rw")
          pi.succeed("touch /nix/x /boot/x && rm /nix/x /boot/x")
          pi.succeed("nix-store --verify-path /run/current-system")
          pi.succeed("sd-ro")
          assert_sd_read_only()
    '';
}
