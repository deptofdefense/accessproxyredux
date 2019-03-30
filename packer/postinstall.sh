#!/bin/sh
cd /etc/nixos
ls -alh
ls -alh src
cat *
NIX_PATH=nixpkgs=$(nix-build --quiet ./src/nixpkgs.nix):nixos-config=/etc/nixos/configuration.nix
nixos-rebuild switch
nix-collect-garbage -d
