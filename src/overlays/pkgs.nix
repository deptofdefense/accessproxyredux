self: super: {
  policyengine = self.callPackage ../policyengine {};
  opa = self.callPackage ../opa {};
  traefik2 = super.traefik.overrideAttrs (old: {
    src = super.fetchgit {
      rev = "cfb356c68e71564b0caa6de986db322ed2198791";
      url = "https://github.com/containous/traefik";
      sha256 = "02js4r52p0hg9j5hl8q0ry55zf98hrjgc32nj3ghr4vc0ppac0fd";
    };
  });
}
