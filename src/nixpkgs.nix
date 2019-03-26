# update nixpkgs-version.json:
# nix-prefetch-git https://github.com/NixOS/nixpkgs.git de0612c46cf17a368e92eaac91fd94affbe36488 > nixpkgs-version.json
let
   hostPkgs = import <nixpkgs> {};
   pinnedVersion = hostPkgs.lib.importJSON ./nixpkgs-version.json;
   pinnedPkgs = hostPkgs.fetchFromGitHub {
     owner = "NixOS";
     repo = "nixpkgs";
     inherit (pinnedVersion) rev sha256;
   };
 
   patches = [
     ./overlays/0001-docker-decl.patch
     ./overlays/0001-Temp-fix-for-Azure-in-NixOps.patch
   ];
 
   patchedPkgs = hostPkgs.runCommand "nixpkgs-custom"
     {
       inherit pinnedPkgs;
       inherit patches;
     }
     ''
       cp -r $pinnedPkgs $out
       chmod -R +w $out
       for p in $patches; do
         echo "Applying patch $p";
         patch -d $out -p1 < "$p";
       done
     '';
 in patchedPkgs
