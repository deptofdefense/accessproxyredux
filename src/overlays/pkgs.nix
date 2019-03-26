self: super: {
  policyengine = self.callPackage ../policyengine {};
  opa = self.callPackage ../opa {};
  traefik2 = super.traefik.overrideAttrs (old: {
    patches = [ ../traefik/reorderMiddleware.patch];
  });
}
