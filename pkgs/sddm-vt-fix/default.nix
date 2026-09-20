# Backport of sddm PR #2204 (one-line VT fix): on Wayland user login the VT
# switch to the session VT blocks for the kernel's 30 s VT_TIMEOUT because the
# greeter compositor holds VT_PROCESS and never acks the release signal.
# waitForStarted() then logs "Session started false", sddm-helper exits, and
# SDDM respawns a greeter — the "SDDM starts twice" bug (upstream #2129).
# Upstream PR is still unmerged; drop this when a sddm release ships it.
#
# `kdePackages.sddm.override { sddm-unwrapped = ...; }` alone loses nixpkgs'
# extraPackages (the spliced-kde-scope override drops them), so the rebuilt
# sddm-wrapped ends up without qtwayland/layer-shell-qt and the greeter dies
# with "no Qt platform plugin could be initialized" (the 2026-09-16 boot
# stall). Re-supply the same list nixpkgs passes so the wrapper keeps its
# Wayland/Plasma runtime deps.
{
  kdePackages,
  ...
}:
let
  sddm-vt-fix-unwrapped = kdePackages.sddm-unwrapped.overrideAttrs (old: {
    patches = (old.patches or [ ]) ++ [
      ./sddm-2204.patch
    ];
  });
in
kdePackages.sddm.override {
  sddm-unwrapped = sddm-vt-fix-unwrapped;
  extraPackages = with kdePackages; [
    breeze-icons
    kirigami
    layer-shell-qt
    libplasma
    plasma5support
    qtsvg
    qtvirtualkeyboard
    qtwayland
  ];
}
