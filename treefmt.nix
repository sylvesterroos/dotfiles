{
  pkgs,
  ...
}:

{
  projectRootFile = "flake.nix";

  # Nix (110 files) — same formatter the flake used standalone
  programs.nixfmt.enable = true;

  # JSON (Zed settings/keymaps)
  programs.jsonfmt.enable = true;

  # YAML (compose.yaml, .sops.yaml)
  programs.yamlfmt.enable = true;

  # TOML (starship.toml, gitu config.toml)
  programs.taplo.enable = true;

  # Nushell (treefmt-nix has no built-in nufmt module)
  settings.formatter.nufmt = {
    command = "${pkgs.nufmt}/bin/nufmt";
    includes = [ "*.nu" ];
  };

  # Never touch sops-encrypted secrets; the YAML MAC covers the whole tree.
  # Zed config files are JSONC — comments are part of the format.
  settings.excludes = [
    "secrets/secrets.yaml"
    "**/zed/*.json"
    ".zed/settings.json"
  ];
}
