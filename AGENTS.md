# NixOS Dotfiles

## Build Commands
- Build a host: `nh os build` (hosts: creek, delta, bachus); home-manager builds along with it on creek and delta
- Evaluate an option: `nix eval .#nixosConfigurations.<host>.config.<option>`
- Format: `nix fmt`
- Update inputs: `nu update.nu` — updates `flake.lock` and reports which `pins.nix` entries can be dropped

## Pins
`pins.nix` holds every package held back or patched ahead of upstream, with the reason and upstream link: nixpkgs packages served from an older revision, upstream fixes added to a package, and flake inputs locked to a commit. Modules use plain package names; the `pins` overlay swaps in the pinned build and applies the patches, which live in `patches/`.

## Architecture
Dendritic layout on flake-parts, following [mightyiam/dendritic](https://github.com/mightyiam/dendritic) and [Dendritic Design with Flake Parts](https://github.com/Doc-Steve/dendritic-design-with-flake-parts): every `.nix` file under `modules/` is a flake-parts module, loaded by import-tree. Files are ordered by feature, and a feature file configures every layer it touches (NixOS and home-manager) in one place. The standard `flake.modules` registry holds reusable modules. Typed top-level options hold shared values; lower-level modules capture those values from the top-level `config`.

- `flake.nix` — inputs only; outputs come from `modules/`
- `modules/flake/` — flake plumbing: systems, overlays and packages, formatter, and `hosts.nix`, which turns each `configurations.nixos.<host>` into a NixOS system
- `modules/*.nix` — features. Each adds to a role: `flake.modules.nixos.base` (every host), `flake.modules.nixos.desktop` (creek, delta), and the matching `flake.modules.homeManager.{base,desktop}`. Individually selected features have a named module that the host imports.
- `modules/hosts/<host>/` — a host's roles, hardware and host-only services, as `flake.modules.nixos.<host>` and `flake.modules.homeManager.<host>`
- `pkgs/` — custom packages
- `overlays/` — nixpkgs overlays
- `secrets/` — sops-nix encrypted secrets (`.sops.yaml`)

Home-manager runs as a NixOS module on the desktop hosts; home modules read the system through `osConfig`. Bachus runs without home-manager and gets its user tools from `flake.modules.nixos.without-home-manager`.

## Service Sources
`config.serviceFrom` selects a service's NixOS module and package from one package set. Capture it and `config.multiverse` in the top-level module, then import its result into the host module:

```nix
{ config, ... }:
let
  mv = config.multiverse;
  inherit (config) serviceFrom;
in
{
  flake.modules.nixos.bachus.imports = [
    (serviceFrom {
      pkgs = mv.tip;
      name = "immich";
      module = "services/web-apps/immich.nix";
    })
  ];
}
```

Keep service settings in the host module. Test the unstable Immich module and package against the stable NixOS base with `nix eval --extra-experimental-features pipe-operators --impure --json --file tests/default.nix`.

## Code Style
- All Nix files formatted with `nixfmt` (the formatter declared in the flake)
- A module that reads its own files (configs, scripts, patches) lives in a folder named after it, together with those files
- Shared project files are resolved through `inputs.self`; feature-owned files use paths relative to their module
- Putting a feature in a role enables it for that role; hosts select individual features by importing their named module
- Each feature brings its own wiring: what it needs from another module (a Syncthing folder, a tailnet service, a firewall port) is declared in the feature's own file, so a host evaluates exactly the features it selects. For example, the agent vault's Syncthing folder lives in `llm-agents.nix`, and the Syncthing modules hold only general folders
- Options (`my.<name>`) exist only where a host sets a value
- Each feature declares the sops secrets it reads; never commit plaintext secrets
