let nixpkgs = import ./src/nixpkgs.nix;
in
{ config, pkgs, ... }:

{
  imports = [ 
    ./hardware-configuration.nix 
    <nixpkgs/nixos/modules/profiles/minimal.nix>
    #<nixpkgs/nixos/modules/virtualisation/virtualbox-image.nix>
  ];
  nixpkgs.overlays = [ 
    (import ./src/overlays/pkgs.nix)
  ];

  # Use the GRUB 2 boot loader.
  boot.loader.grub.enable = true;
  boot.loader.grub.version = 2;
  boot.loader.grub.device = "/dev/sda";
  /*
  fileSystems."/" {
    device = "/dev/
  };
  */
  nix.nixPath = ["nixpkgs=${nixpkgs}:nixos-config=/etc/nixos/configuration.nix" ];
 
  users.mutableUsers = false;
  services.openssh.enable = true;
  services.openssh.permitRootLogin = "yes";

  # Kube
  environment.systemPackages = with pkgs; [ 
    kompose kubectl
    policyengine 
  ];
  networking.enableIPv6 = false;

  networking.extraHosts = ''
    127.0.0.1 api.kube
    '';

  services.kubernetes = {
    easyCerts = true;
    addons.dashboard.enable = true;
    roles = ["master" "node"];
    masterAddress = "kube";
    kubelet.seedDockerImages = let

      policyengine-image = pkgs.dockerTools.buildLayeredImage {
        name = "policyengine";
        tag = "latest";

        contents = [ pkgs.policyengine pkgs.busybox];
        config = {
          Cmd = [ "${pkgs.policyengine}/bin/cmd" "--help" ];
          WorkingDir = "/data";
          Volumes = {
            "/data" = {};
          };
        };
      };

  in [policyengine-image ];
  };
  services.etcd.enable = true;
  services.dockerRegistry.enable = true;


  networking.firewall.allowedTCPPorts = [22 80 443];

  users.users.root = {
    password = "root";
  };
}
