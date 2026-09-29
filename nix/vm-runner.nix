# Boots the disko-built VM image with persistent state.
#   nix run .#vm            # 3D accelerated (virgl)
#   nix run .#vm -- --no-gl # software rendering fallback
# State lives in $NIXOS_VM_DIR (default ~/.local/share/nixos-vm); delete
# it to start over from a freshly built image.
{
  writeShellApplication,
  qemu,
  OVMF,
  mesa,
  coreutils,
  image,
}:

writeShellApplication {
  name = "run-nixos-vm";
  runtimeInputs = [
    qemu
    coreutils
  ];
  text = ''
    dir="''${NIXOS_VM_DIR:-$HOME/.local/share/nixos-vm}"
    mkdir -p "$dir"
    disk="$dir/disk.qcow2"
    vars="$dir/OVMF_VARS.fd"

    if [ ! -e "$disk" ]; then
      echo "Creating $disk from ${image}"
      # Keep the backing image alive across nix garbage collections.
      nix-store --add-root "$dir/base" --realise ${image} >/dev/null
      qemu-img create -f qcow2 -b "$dir/base/main.qcow2" -F qcow2 "$disk"
    fi
    if [ ! -e "$vars" ]; then
      install -m 644 ${OVMF.variables} "$vars"
    fi

    display=(-device virtio-vga-gl -display "gtk,gl=on")
    if [ "''${1:-}" = "--no-gl" ]; then
      shift
      display=(-device virtio-vga -display gtk)
    else
      # nixpkgs' qemu can't see the host distro's GL drivers; point it
      # at nixpkgs' mesa instead.
      export __EGL_VENDOR_LIBRARY_DIRS=${mesa}/share/glvnd/egl_vendor.d
      export GBM_BACKENDS_PATH=${mesa}/lib/gbm
      export LIBGL_DRIVERS_PATH=${mesa}/lib/dri
    fi

    exec qemu-system-x86_64 \
      -name nixos-vm \
      -enable-kvm -machine q35 -cpu host \
      -smp "''${NIXOS_VM_CORES:-4}" -m "''${NIXOS_VM_MEMORY:-8G}" \
      -drive if=pflash,format=raw,readonly=on,file=${OVMF.firmware} \
      -drive if=pflash,format=raw,file="$vars" \
      -drive file="$disk",if=virtio,format=qcow2,cache=writeback \
      -nic user,model=virtio-net-pci,hostfwd=tcp:127.0.0.1:2222-:22 \
      -device qemu-xhci -device usb-tablet \
      -audiodev pipewire,id=snd0 -device intel-hda -device hda-duplex,audiodev=snd0 \
      "''${display[@]}" \
      "$@"
  '';
}
