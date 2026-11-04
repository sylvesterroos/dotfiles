# TR-100 Machine Report from usgraphics/usgc-machine-report at 1c16ec0.
# The script is vendored; edit machine_report.sh directly.
{
  lib,
  stdenvNoCC,
  makeWrapper,
  coreutils,
  gawk,
  gnugrep,
  gnused,
  hostname,
  iproute2,
  procps,
  util-linux,
}:

stdenvNoCC.mkDerivation {
  pname = "usgc-machine-report";
  version = "0-unstable-2026-05-05";

  src = lib.fileset.toSource {
    root = ./.;
    fileset = ./machine_report.sh;
  };

  nativeBuildInputs = [ makeWrapper ];

  dontBuild = true;

  installPhase = ''
    runHook preInstall
    install -D --mode=0755 machine_report.sh $out/bin/machine-report
    wrapProgram $out/bin/machine-report \
      --set PATH ${
        lib.makeBinPath [
          procps
          coreutils
          gawk
          gnugrep
          gnused
          hostname
          iproute2
          util-linux
        ]
      }
    runHook postInstall
  '';

  meta = {
    description = "TR-100 Machine Report: a tabular system summary for login shells";
    homepage = "https://github.com/usgraphics/usgc-machine-report";
    license = lib.licenses.bsd3;
    mainProgram = "machine-report";
    platforms = lib.platforms.linux;
  };
}
