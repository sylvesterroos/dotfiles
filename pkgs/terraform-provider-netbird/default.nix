# OpenTofu provider for the NetBird management API.
{
  nix-update-script,
  terraform-providers,
}:
let
  version = "0.0.11";
in
(terraform-providers.mkProvider {
  owner = "netbirdio";
  repo = "terraform-provider-netbird";
  rev = "v${version}";
  inherit version;
  spdx = "BSD-3-Clause";
  hash = "sha256-ojtMtGmSokA6x1ut09W6Oc8ESGT0fpLoorc5XNQvpyY=";
  vendorHash = "sha256-s5UVLL+BZX8dTGL8SZXvPJcyPFxzIOf0VEW9iYZZ1b8=";
  homepage = "https://registry.terraform.io/providers/netbirdio/netbird";
}).overrideAttrs
  (old: {
    passthru = old.passthru // {
      updateScript = nix-update-script { extraArgs = [ "--flake" ]; };
    };
  })
