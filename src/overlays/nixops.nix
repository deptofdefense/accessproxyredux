self: super : rec {
  # Using own fork of nixops
  # -1) check region and zone before using privateIPv4
  # -2) use output resource, PR submitted
  # 3) make nixops overridable
  python2Packages = super.python2Packages.override {
    overrides = #{};
    (self: super2: let callPackage = super.newScope self; in {
      azure-mgmt-compute = callPackage <nixpkgs/pkgs/tools/package-management/nixops/azure-mgmt-compute> { };
      azure-mgmt-network = callPackage <nixpkgs/pkgs/tools/package-management/nixops/azure-mgmt-network> { };
      azure-mgmt-nspkg = callPackage <nixpkgs/pkgs/tools/package-management/nixops/azure-mgmt-nspkg> { };
      azure-mgmt-resource = callPackage <nixpkgs/pkgs/tools/package-management/nixops/azure-mgmt-resource> { };
      azure-mgmt-storage = callPackage <nixpkgs/pkgs/tools/package-management/nixops/azure-mgmt-storage> { };
    });
  };
  nixopsSrc = self.fetchFromGitHub {
        owner = "tomberek";
        repo = "nixops";
		rev = "3c007d6b3f6a1a931ade2562ba3f7cbca87e4222";
		sha256 = "167pyzfyvmn8d859yxhr6ysxf9i39p4g7zhdl4s0gr8qjzvvl9mj";
      };

  nixopsUnstable3 = (import "${nixopsSrc}/release.nix" {
    officialRelease = true;
  }).build.${builtins.currentSystem};
}
