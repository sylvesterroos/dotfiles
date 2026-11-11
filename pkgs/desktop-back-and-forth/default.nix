{ lib, stdenv }:

stdenv.mkDerivation {
  pname = "desktop-back-and-forth";
  version = "1";

  src = ./package;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/share/kwin/scripts/desktop-back-and-forth
    cp -a . $out/share/kwin/scripts/desktop-back-and-forth

    runHook postInstall
  '';

  meta = {
    description = "KWin script: Meta+<n> on the current desktop returns to the previously used desktop";
    license = lib.licenses.gpl2Plus;
    platforms = lib.platforms.linux;
  };
}
