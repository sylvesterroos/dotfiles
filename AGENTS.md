# NixOS Dotfiles

## Build Commands
- Build NixOS config: `nh os build` (hosts: creek, delta, bachus)
- Build home-manager config: `nh home build`
- Evaluate a module: `nix eval .#nixosConfigurations.<host>.config.<option>`

## Architecture
- `flake.nix` — entry point; defines inputs, NixOS/home-manager configurations, overlays, and custom packages
- `hosts/` — per-host configs (creek, delta, bachus). Each has `configuration.nix` and `home-manager/home.nix`
- `modules/nixos/my/` — reusable NixOS modules, auto-imported via `default.nix`; each exposes `my.<name>` options
- `modules/home-manager/my/` — reusable home-manager modules with `my.<name>` options
- `pkgs/` — custom packages;
- `overlays/` — nixpkgs overlays;
- `secrets/` — sops-nix encrypted secrets (`.sops.yaml`)

## Code Style
- All Nix files formatted with `nixfmt` (the formatter declared in the flake)
- Modules follow NixOS module pattern: `{ config, lib, ... }: { options.my.<name> = ...; config = ...; }`
- Use `mkEnableOption`/`mkOption` for options; use `with lib;` or `lib.` prefix for lib functions
- Secrets via sops-nix; never commit plaintext secrets
