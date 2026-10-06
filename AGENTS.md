# NixOS Dotfiles

## Build Commands
- Build a host: `nh os build` (hosts: creek, delta, bachus); home-manager builds along with it on creek and delta
- Evaluate an option: `nix eval .#nixosConfigurations.<host>.config.<option>`
- Format: `nix fmt`
- Update inputs: `nu update.nu` — updates `flake.lock` and reports which `pins.nix` entries can be dropped

## Pins
`pins.nix` holds every package held back because it fails to build upstream, with the reason and upstream link. Modules use plain package names; the `pins` overlay swaps in the pinned build.

## Architecture
Dendritic layout on flake-parts: every `.nix` file under `modules/` is a flake-parts module, loaded by import-tree. Files are ordered by feature, and a feature file configures every layer it touches (NixOS and home-manager) in one place.

- `flake.nix` — inputs only; outputs come from `modules/`
- `modules/flake/` — flake plumbing: systems, overlays and packages, formatter, and `hosts.nix`, which turns each `configurations.nixos.<host>` into a NixOS system
- `modules/*.nix` — features. Each adds to a role: `flake.modules.nixos.base` (every host), `flake.modules.nixos.desktop` (creek, delta), and the matching `flake.modules.homeManager.{base,desktop}`
- `modules/hosts/<host>/` — a host's roles, hardware and host-only services, as `flake.modules.{nixos,homeManager}.<host>`
- `pkgs/` — custom packages
- `overlays/` — nixpkgs overlays
- `secrets/` — sops-nix encrypted secrets (`.sops.yaml`)

Home-manager runs as a NixOS module on the desktop hosts; home modules read the system through `osConfig`. Bachus runs without home-manager and gets its user tools from `flake.modules.nixos.without-home-manager`.

## Code Style
- All Nix files formatted with `nixfmt` (the formatter declared in the flake)
- A module that reads its own files (configs, scripts, patches) lives in a folder named after it, together with those files
- Putting a feature in a role is its switch; enable options are for features a host picks individually
- Options (`my.<name>`) exist only where a host sets a value
- Each feature declares the sops secrets it reads; never commit plaintext secrets
