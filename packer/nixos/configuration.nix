let nixpkgs = import ./src/nixpkgs.nix;
in
{ config, pkgs, ... }:

{
  imports = [ 
    ./hardware-configuration.nix 
    <nixpkgs/nixos/modules/profiles/minimal.nix>
    #<nixpkgs/nixos/modules/virtualisation/virtualbox-image.nix>
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
 
  nixpkgs.overlays = [
  ];
  users.mutableUsers = false;

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;
  services.openssh.permitRootLogin = "yes";

  # we always want git and vim
  environment.systemPackages = with pkgs; [ 
    gitMinimal vim tree
    kompose kubectl
  ];

  services.kubernetes = {
    easyCerts = true;
    addons.dashboard.enable = true;
    roles = ["master" "node"];
    apiserver = {
      securePort = 443;
      advertiseAddress = "hostname";
    };
    masterAddress = "localhost";
  };
  services.etcd.enable = true;
  services.dockerRegistry.enable = true;


  networking.firewall.allowedTCPPorts = [22 80 443];

  users.users.root = {
    password = "root";
  };
}
