{
  lib,
  stdenv,
  fetchurl,
  autoPatchelfHook,
  writeShellScript,
  curl,
}:
let
  # Proton's release manifest, refreshed by passthru.updateScript. The newest
  # stable release supplies the version, download URL and checksum.
  release = lib.last (
    lib.sort (a: b: lib.versionOlder a.Version b.Version) (
      lib.filter (release: release.CategoryName == "Stable") (lib.importJSON ./version.json).Releases
    )
  );

  platforms = {
    x86_64-linux = "linux/x64";
    aarch64-linux = "linux/arm64";
  };

  platform =
    platforms.${stdenv.hostPlatform.system}
      or (throw "proton-drive-cli: unsupported platform ${stdenv.hostPlatform.system}");
  file = lib.findFirst (
    file: file.Platform == platform
  ) (throw "proton-drive-cli: ${release.Version} has no ${platform} build") release.Files;
in
stdenv.mkDerivation {
  pname = "proton-drive-cli";
  version = release.Version;

  src = fetchurl {
    url = file.Url;
    sha512 = file.Sha512CheckSum;
  };

  dontUnpack = true;
  # Bun keeps the bundled program at the end of the executable; stripping removes it.
  dontStrip = true;

  nativeBuildInputs = [ autoPatchelfHook ];
  buildInputs = [ stdenv.cc.cc.lib ];

  installPhase = ''
    runHook preInstall
    install -Dm755 $src $out/bin/proton-drive
    runHook postInstall
  '';

  # Runs from the repository root.
  passthru.updateScript = writeShellScript "update-proton-drive-cli" ''
    ${lib.getExe curl} --fail --silent --show-error --location \
      --output pkgs/proton-drive-cli/version.json \
      https://proton.me/download/drive/cli/version.json
  '';

  meta = {
    description = "Proton's official command-line client for Proton Drive";
    homepage = "https://github.com/ProtonDriveApps/sdk/tree/main/cli";
    license = lib.licenses.mit;
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
    platforms = builtins.attrNames platforms;
    mainProgram = "proton-drive";
  };
}
