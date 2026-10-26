{
  lib,
  stdenv,
  fetchFromGitLab,
  nix-update-script,
}:

stdenv.mkDerivation {
  pname = "switch-to-previous-desktop";
  version = "unstable-2024-02-29";

  src = fetchFromGitLab {
    domain = "invent.kde.org";
    owner = "vladz";
    repo = "switch-to-previous-desktop";
    rev = "3796aabfe915905cbd7139cab252ab5c54a07084";
    hash = "sha256-LsjQOdhtkdoxwNyKrt/ahevnMrIJ3q0R9OTo+2l/2GQ=";
  };

  installPhase = ''
    runHook preInstall

    mkdir -p $out/share/kwin/scripts
    cp -a package $out/share/kwin/scripts/switch-to-previous-desktop

    runHook postInstall
  '';

  passthru.updateScript = nix-update-script {
    extraArgs = [
      "--flake"
      "--version=branch"
    ];
  };

  meta = with lib; {
    description = "KWin script: switch to the previously used virtual desktop";
    homepage = "https://invent.kde.org/vladz/switch-to-previous-desktop";
    license = licenses.gpl2Plus;
    platforms = platforms.linux;
  };
}
