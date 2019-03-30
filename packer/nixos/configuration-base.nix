{ config, pkgs, ... }:

{
  imports = [ 
    ./hardware-configuration.nix 
    <nixpkgs/nixos/modules/profiles/minimal.nix>
  ];

  # Use the GRUB 2 boot loader.
  boot.loader.grub.enable = true;
  boot.loader.grub.version = 2;
  boot.loader.grub.device = "/dev/sda";

  users.mutableUsers = false;
  services.openssh.enable = true;
  services.openssh.permitRootLogin = "yes";

  nix.nixPath = ["nixpkgs=${<nixpkgs>}:nixos-config=/etc/nixos/configuration.nix" ];

  networking.firewall.allowedTCPPorts = [22 80 443];

  users.users.root = {
    password = "root";
  };
}
