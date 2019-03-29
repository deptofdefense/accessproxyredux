let
  common= import <config.nix>;
  pkgs = import <nixpkgs>{};
  lib = pkgs.lib;

  commonDeployment = {name, resources} : {
    deployment.keys."wg.priv" = let 
      a = resources.output."wg_key_${name}".value;
      in if a == null then {} else {
      text = (builtins.fromJSON a).priv;
    };
    deployment.targetEnv = common.instances.ace.targetEnv;
    deployment.ec2 = if common.instances."${name}".targetEnv == "ec2" then {
        securityGroups = [ resources.ec2SecurityGroups.office-sg ];
        tags.Project="zerotrust";
        ebsInitialRootDiskSize = 30;
        ebsOptimized = true;
        associatePublicIpAddress = true;
        instanceType = "t3.large";
    } // common.instances."${name}".ec2 else {};
    deployment.virtualbox = 
      if common.instances."${name}".targetEnv == "virtualbox" then {
        memorySize = 4096; # megabytes
        vcpu = 2; # number of cpus
        headless = true;
      } else {};
  };

  machine-ace = { config, pkgs, name, resources, ... }: lib.recursiveUpdate {
    inherit common;
    networking.firewall.allowedTCPPorts = [22 80 443 ];
    imports = [ 
      ./modules/common.nix
      ./modules/ace.nix
    ]
      ++ (if common.instances.ace.targetEnv == "ec2" then 
      [<nixpkgs/nixos/modules/virtualisation/amazon-image.nix>] else []);

    deployment = (commonDeployment {inherit name resources;}).deployment;
  } common.instances.ace.extraConfig;

  machine-office = { config, pkgs, name, resources, ... }: lib.recursiveUpdate {
    inherit common;
    imports = [ 
      ./modules/common.nix
      ./modules/office.nix
    ]
      ++ (if common.instances.office.targetEnv == "ec2" then 
      [<nixpkgs/nixos/modules/virtualisation/amazon-image.nix>] else []);

    deployment = (commonDeployment {inherit name resources;}).deployment;
  } common.instances.office.extraConfig;

in {
  ace = machine-ace;
  office = machine-office;

  network.description = "zerotrust-office";
  network.enableRollback = true;

  resources = common.resources;
}

