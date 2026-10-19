{
  lib,
  stdenv,
  fetchFromGitHub,
  qt6Packages,
}:

stdenv.mkDerivation {
  pname = "omawrite";
  version = "0.7.2";

  src = fetchFromGitHub {
    owner = "omacom";
    repo = "omawrite";
    tag = "v0.7.2";
    hash = "sha256-kjbiI5Wo/vX9Fs3XnN1K3PWPOtOIX85ZLFOL1HBl6t0=";
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
