# Updates flake.lock, then reports which entries in pins.nix can be dropped.
#
# A nixpkgs pin can go once cache.nixos.org has built every package in its
# group at the new tip: Hydra publishes only what builds.
# A patch can go once the package's source on tip, with nixpkgs' own patches
# applied, already contains it: the patch then undoes cleanly.
# A flake-input pin can go once upstream has moved past the broken commit and
# the new commit builds.
const root = path self .
def tip-outputs [] {
    let expr = $"
    let
      flake = builtins.getFlake \"($root)\";
      tip = \(flake.inputs.multiverse.lib.mkMultiverse { system = \"x86_64-linux\"; }\).tip;
      out = name: let r = builtins.tryEval tip.${name}.outPath; in if r.success then r.value else null;
    in
    builtins.mapAttrs \(_: group: map \(name: { inherit name; out = out name; }\) group.packages\)
      \(import ($root)/pins.nix\).nixpkgs
  "
    nix eval --impure --json --expr $expr | from json
}
def cached [out: string] {
    let hash = $out | path basename | str substring 0..31
    (http get --full --allow-errors $"https://cache.nixos.org/($hash).narinfo" | get status) == 200
}
def check-nixpkgs [] {
    tip-outputs | items { |group, packages|
    let missing = $packages | where { |p| $p.out == null or not (cached $p.out) } | get name
    if ($missing | is-empty) {
      { pin: $group, verdict: "DROP", detail: "every package is built on tip" }
    } else {
      { pin: $group, verdict: "keep", detail: $"not built on tip: ($missing | str join ', ')" }
    }
  }
}
def check-inputs [] {
    let lock = open --raw $"($root)/flake.lock" | from json | get nodes
    let inputs = nix eval --json --file $"($root)/pins.nix" inputs | from json
    $inputs | items { |name, pin|
    let locked = $lock | get $name | get locked
    let repo = $"github:($locked.owner)/($locked.repo)"
    let head = git ls-remote $"https://github.com/($locked.owner)/($locked.repo)" HEAD | split row "\t" | first
    if $head == $pin.broken {
      { pin: $name, verdict: "keep", detail: "upstream has no commits past the broken one" }
    } else {
      print $"building ($repo)/($head | str substring 0..6) …"
      let build = nix build --no-link $"($repo)/($head)#packages.x86_64-linux.default" | complete
      if $build.exit_code == 0 {
        { pin: $name, verdict: "DROP", detail: $"($head | str substring 0..6) builds; set the url back to ($repo)" }
      } else {
        { pin: $name, verdict: "keep", detail: $"($head | str substring 0..6) still fails to build" }
      }
    }
  }
}
def check-patches [] {
    let names = nix eval --json --file $"($root)/pins.nix" patches --apply builtins.attrNames | from json
    $names | each { |name|
    let expr = $"
    let
      flake = builtins.getFlake \"($root)\";
      tip = \(flake.inputs.multiverse.lib.mkMultiverse { system = \"x86_64-linux\"; }\).tip;
      pin = \(import ($root)/pins.nix\).patches.\"($name)\";
      pkg = tip.lib.getAttrFromPath pin.package tip;
    in
    tip.stdenvNoCC.mkDerivation {
      name = \"pin-check-($name)\";
      inherit \(pkg\) src;
      patches = pkg.patches or [ ];
      dontConfigure = true;
      dontBuild = true;
      dontFixup = true;
      installPhase = ''
        if patch -p1 --dry-run -s -f < ${pin.patch} > /dev/null; then echo applies
        elif patch -R -p1 --dry-run -s -f < ${pin.patch} > /dev/null; then echo contained
        else echo conflicts
        fi > $out
      '';
    }
  "
    let build = nix build --no-link --print-out-paths --impure --expr $expr | complete
    if $build.exit_code != 0 {
      error make { msg: $"checking patch ($name) failed: ($build.stderr | str trim)" }
    }
    match (open ($build.stdout | str trim) | str trim) {
      "contained" => { pin: $name, verdict: "DROP", detail: "tip's source already contains the fix" }
      "applies" => { pin: $name, verdict: "keep", detail: "tip's source lacks the fix" }
      _ => { pin: $name, verdict: "keep", detail: "patch no longer applies on tip; refresh it or check whether upstream fixed it differently" }
    }
  }
}
def main [] {
    cd $root
    nix flake update
    print ""
    print (
        check-nixpkgs | append (check-patches) | append (check-inputs) | table --index false
    )
}
