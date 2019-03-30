# update nixpkgs-version.json:
# nix-prefetch-git https://github.com/NixOS/nixpkgs.git de0612c46cf17a368e92eaac91fd94affbe36488 > nixpkgs-version.json
let
   pinnedVersion = with builtins; fromJSON (readFile ./nixpkgs-version.json);
   fetcher = { owner, repo, rev, sha256 }: builtins.fetchTarball {
     inherit sha256;
     url = "https://github.com/${owner}/${repo}/archive/${rev}.tar.gz";
   };
   pinnedPkgs = fetcher {
     owner = "NixOS";
     repo = "nixpkgs";
     inherit (pinnedVersion) rev sha256;
   };
 
   patches = [
     #./overlays/0001-docker-decl.patch
     #./overlays/0001-Temp-fix-for-Azure-in-NixOps.patch
   ];
 
   patchedPkgs = let 
     rev = "nixpkgs-" + builtins.substring 0 8 pinnedVersion.rev;
     in 
     (import pinnedPkgs{}).runCommand rev
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
       echo -n ${rev} > $out/.git-revision
     '';
 in
    patchedPkgs
