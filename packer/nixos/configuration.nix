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
  boot.kernelParams = ["video=640x480"];
  nix.nixPath = ["nixpkgs=${nixpkgs}:nixos-config=/etc/nixos/configuration.nix" ];
 
  users.mutableUsers = false;
  services.openssh.enable = true;
  services.openssh.permitRootLogin = "yes";

  # Kube
  environment.systemPackages = with pkgs; [ 
    kompose kubectl
    policyengine 
    gitMinimal vim
  ];
  networking.enableIPv6 = false;

  networking.extraHosts = ''
    127.0.0.1 api.kube
    '';

  services.kubernetes = {
    easyCerts = true;
    addons.dashboard.enable = true;
    roles = ["master" "node"];
    masterAddress = "api.kube";
    kubelet.seedDockerImages = [

      (pkgs.dockerTools.buildLayeredImage {
        name = "policyengine";
        tag = "latest";
        config = {
          Cmd = [ "${pkgs.policyengine}/bin/cmd" "--help" ];
          WorkingDir = "/data";
          Volumes = {
            "/data" = {};
          };
        };
      })

      (pkgs.dockerTools.buildLayeredImage {
        name = "opa";
        tag = "latest";
        config = {
          Cmd = [ "${pkgs.opa}/bin/opa" "--help" ];
          WorkingDir = "/data";
          Volumes = {
            "/data" = {};
          };
        };
      })

      (pkgs.dockerTools.buildLayeredImage {
        name = "traefik";
        tag = "latest";
        config = {
          Cmd = [ "${pkgs.traefik2}/bin/traefik" "--help" ];
          WorkingDir = "/data";
          Volumes = {
            "/data" = {};
          };
        };
      })
    ];

  };
  services.etcd.enable = true;
  services.dockerRegistry.enable = true;


  networking.firewall.allowedTCPPorts = [22 80 443];

  users.users.root = {
    password = "root";
  };
}
