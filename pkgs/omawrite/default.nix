{
  lib,
  stdenv,
  fetchFromGitHub,
  qt6Packages,
}:

stdenv.mkDerivation {
  pname = "omawrite";
  version = "0.1.0-unstable-2026-09-16";

  src = fetchFromGitHub {
    owner = "omacom";
    repo = "omawrite";
    rev = "8f98892b26768236b2c20f4e637cf4b102d898bf";
    hash = "sha256-yS3GOL/kc03qx4naWzUdSZwAYxMuCjvrgmhexpwjsfA=";
  };

  nativeBuildInputs = [
    qt6Packages.qmake
    qt6Packages.wrapQtAppsHook
  ];

  buildInputs = with qt6Packages; [
    qtbase
    qtdeclarative
  ];

  installPhase = ''
    runHook preInstall

    install -Dm755 omawrite $out/bin/omawrite
    install -Dm644 LICENSE $out/share/licenses/omawrite/LICENSE
    install -Dm644 fonts/OFL.txt $out/share/licenses/omawrite/OFL.txt
    install -Dm644 pkgbuild/omawrite.svg $out/share/icons/hicolor/scalable/apps/omawrite.svg
    install -Dm644 pkgbuild/omawrite.desktop $out/share/applications/omawrite.desktop

    runHook postInstall
  '';

  meta = {
    description = "Dead-simple Markdown writing app built with Qt Quick that follows system dark/light mode";
    homepage = "https://github.com/omacom/omawrite";
    license = lib.licenses.mit;
    platforms = lib.platforms.linux;
    mainProgram = "omawrite";
  };
}
