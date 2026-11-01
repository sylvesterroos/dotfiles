# Shader Wallpaper for Plasma 6, with its native engine (a QML module built
# into the wallpaper package). The KDE Store version compiles the engine on
# the user's machine with build.sh, which cannot find NixOS's libraries.
{
  lib,
  stdenv,
  fetchFromGitHub,
  nix-update-script,
  cmake,
  extra-cmake-modules,
  gettext,
  pkg-config,
  wrapQtAppsHook,
  qtbase,
  qtdeclarative,
  kconfig,
  ki18n,
  kpackage,
  kitemmodels,
  kwindowsystem,
  libplasma,
  plasma-workspace,
  pipewire,
  libxcb,
  shaderc,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "shader-wallpaper";
  version = "4.2.4";

  src = fetchFromGitHub {
    owner = "y4my4my4m";
    repo = "kde-shader-wallpaper";
    rev = "v${finalAttrs.version}";
    hash = "sha256-H1XNiKQ5t53b5nYn+l/fZShvM86TRkvA8pdVBdsEd5o=";
  };

  nativeBuildInputs = [
    cmake
    extra-cmake-modules
    gettext
    pkg-config
    wrapQtAppsHook
  ];

  buildInputs = [
    qtbase
    qtdeclarative
    kconfig
    ki18n
    kpackage
    kitemmodels
    kwindowsystem
    libplasma
    plasma-workspace
    pipewire
    libxcb
    shaderc
  ];

  # The Plasma Login Manager greeter runs as the plasmalogin user and cannot
  # read shaders kept in the desktop user's home. Shaders under the package's
  # contents/ui/Shaders are resolved against whichever copy of the plugin is
  # running, so shipping one here makes it selectable from the login screen.
  postInstall = ''
    install -Dm644 ${./framework_ascii.glsl} \
      $out/share/plasma/wallpapers/online.knowmad.shaderwallpaper/contents/ui/Shaders/framework_ascii.glsl
  '';

  passthru.updateScript = nix-update-script { extraArgs = [ "--flake" ]; };

  meta = {
    description = "Plasma 6 wallpaper that runs GLSL shaders";
    homepage = "https://github.com/y4my4my4m/kde-shader-wallpaper";
    license = lib.licenses.gpl3Plus;
    platforms = lib.platforms.linux;
  };
})
