{ config, pkgs, inputs, ... }:
let
  kubeMasterIP = "192.168.1.232";
  kubeMasterAPIServerPort = 6443;
in
{
  # resolve master hostname
  networking.extraHosts = "${kubeMasterIP} ${config.networking.hostName}";
  networking.nftables.enable = true;

  programs.bash.interactiveShellInit = builtins.readFile "${inputs.dotfiles}/nixos/.bashrc";

  services.openiscsi = {
    enable = true;
    name = "iqn.2025-08.dev.codecannon:${config.networking.hostName}";
  };

  # Create a symlink for FHS-compliant software like Longhorn
  # that expects iscsiadm in a standard path.
  systemd.tmpfiles.rules = [
    "L /usr/bin/iscsiadm - - - - ${pkgs.openiscsi}/bin/iscsiadm"
  ];

  # packages for administration tasks
  environment.systemPackages = with pkgs; [
    kompose
    kubectl
    kubernetes
    kubectx
    k9s
    openiscsi
    nfs-utils
    nftables
    iptables
    (wrapHelm kubernetes-helm {
      plugins = with pkgs.kubernetes-helmPlugins; [
        helm-secrets
        helm-diff
        helm-s3
        helm-git
      ];
    })
  ];

  services.kubernetes = {
    roles = ["master" "node"];

    apiserver.allowPrivileged = true;

    # For components like kubelet to find the master.
    masterAddress = kubeMasterIP;

    # **THIS IS FOR KUBECTL**
    # It sets the server URL in the generated kubeconfig file.
    # This fixes the new error you are seeing.
    apiserverAddress = "https://${kubeMasterIP}:${toString kubeMasterAPIServerPort}";

    # **THIS IS FOR THE API SERVER PROCESS**
    # It configures the API server itself.
    apiserver = {
      # Tell the API server to listen on the real IP. This fixes the CoreDNS error.
      advertiseAddress = kubeMasterIP;
      # Tell the API server which port to listen on.
      securePort = kubeMasterAPIServerPort;
    };

    controllerManager = {
      clusterCidr = "10.1.0.0/16";
    };

    easyCerts = true;

    # use coredns
    addons.dns.enable = true;

    # enable hairpin so container can ping itself
    kubelet = {
      extraConfig = {
        hairpinMode = "hairpin-veth";
      };
      cni.config = [{
        name = "cbr0";
        type = "flannel";
        cniVersion = "0.3.1";
        delegate = {
          hairpinMode = true;
          isDefaultGateway = true;
          bridge = "mynet";
        };
      }];
    };
    proxy.extraOpts = "--proxy-mode=iptables";

    flannel.enable = true;
    flannel.openFirewallPorts = true;
  };

  systemd.services.kube-proxy.path = [ pkgs.nftables ];

  networking.firewall = {
    enable = true;
    trustedInterfaces = [ "mynet" "cni0" "flannel.1" "docker0" ];
  };
}
