# Updates flake.lock, then reports which entries in pins.nix can be dropped.
#
# A nixpkgs pin can go once cache.nixos.org has built every package in its
# group at the new tip: Hydra publishes only what builds. A group holding a
# package set or function, which Hydra cannot judge, shows TRY once its
# `upstream` link is fixed: remove the pin and build by hand.
# A patch can go once the package's source on tip, with nixpkgs' own patches
# applied, already contains it: the patch then undoes cleanly.
# A flake-input pin can go once upstream has moved past the broken commit and
# the new commit builds.
# A kept pin whose `upstream` PR closed unmerged, or whose issue closed as not
# planned, shows RELINK: point it at the PR or issue that now carries the fix.
const root = path self .
def tip-outputs [] {
    let expr = $"
    let
      flake = builtins.getFlake \"($root)\";
      tip = \(flake.inputs.multiverse.lib.mkMultiverse { system = \"x86_64-linux\"; }\).tip;
      package = name: let
        value = tip.${name};
        derivation = tip.lib.isDerivation value;
        r = builtins.tryEval value.outPath;
      in { inherit name derivation; out = if derivation && r.success then r.value else null; };
    in
    builtins.mapAttrs \(_: group: map package group.packages\) \(import ($root)/pins.nix\).nixpkgs
  "
    nix eval --impure --json --expr $expr | from json
}
def cached [out: string] {
    let hash = $out | path basename | str substring 0..31
    (http get --full --allow-errors $"https://cache.nixos.org/($hash).narinfo" | get status) == 200
}
def check-nixpkgs [links: record] {
    tip-outputs | items { |group, packages|
    let unjudged = $packages | where { |p| not $p.derivation } | get name
    let missing = $packages | where { |p| $p.out == null or not (cached $p.out) } | get name
    if ($unjudged | is-not-empty) {
      let url = $links | get $group
      if (upstream-state $url) == "fixed" {
        { pin: $group, verdict: "TRY", detail: $"($url) is fixed; remove the pin and build" }
      } else {
        { pin: $group, verdict: "keep", detail: $"Hydra can't judge ($unjudged | str join ', '); waiting on ($url)" }
      }
    } else if ($missing | is-empty) {
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
      sourceRoot = pkg.sourceRoot or null;
      postUnpack = pkg.postUnpack or null;
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
# The `upstream` link of each nixpkgs and patch pin, by section and name.
def upstream-links [] {
    nix eval --json --file $"($root)/pins.nix" --apply "p: builtins.mapAttrs (_: builtins.mapAttrs (_: pin: pin.upstream or null)) { inherit (p) nixpkgs patches; }" | from json
}
# Where a GitHub `upstream` link stands: open; fixed (PR merged, issue closed
# as completed); ended (PR closed unmerged, issue closed as not planned), so
# the fix it tracked will never land; or untracked for links outside GitHub.
def upstream-state [url: string] {
    let parsed = $url | parse --regex '^https://github\.com/(?<repo>[^/]+/[^/]+)/(?:pull|issues)/(?<number>\d+)'
    if ($parsed | is-empty) { return "untracked" }
    let issue = http get $"https://api.github.com/repos/($parsed.0.repo)/issues/($parsed.0.number)"
    if $issue.state != "closed" { return "open" }
    let fixed = if ($issue.pull_request? | is-not-empty) {
        $issue.pull_request.merged_at? != null
    } else {
        $issue.state_reason? != "not_planned"
    }
    if $fixed { "fixed" } else { "ended" }
}
# A kept pin whose upstream link has ended needs a new link to wait on.
def relink [links: record] { each { |row|
        let url = $links | get --optional $row.pin
        if $row.verdict == "keep" and $url != null and (upstream-state $url) == "ended" {
            $row | merge { verdict: "RELINK", detail: $"($url) closed without the fix; find its successor · ($row.detail)" }
        } else {
            $row
        }
    } }
def main [] {
    cd $root
    nix flake update
    print ""
    let links = upstream-links
    print (
        check-nixpkgs $links.nixpkgs | relink $links.nixpkgs | append (check-patches | relink $links.patches) | append (check-inputs) | table --index false
    )
}
