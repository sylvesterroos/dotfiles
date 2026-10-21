{
  lib,
  stdenv,
  fetchurl,
  autoPatchelfHook,
}:
let
  version = "0.9.0";

  # Checksums from https://proton.me/download/drive/cli/index.html
  sources = {
    x86_64-linux = {
      platform = "linux-x64";
      sha512 = "3533025ba69ae112b64e3e01fbcc1ad0688136a4043f6cf6a72886967d85fdcd9ec235479c2e113171614be5225bfba93427509a05ca5aa6071d924fa7e91ca8";
    };
    aarch64-linux = {
      platform = "linux-arm64";
      sha512 = "c8d5a6b174e57f06d05cb5483400b9963faf58e743b6b33706bb73ecff718047ffce6b439994255b94b5b226b90d2e91bef7418ec96c1c3f5d8bf39b6cd01321";
    };
  };

  source =
    sources.${stdenv.hostPlatform.system}
      or (throw "proton-drive-cli: unsupported platform ${stdenv.hostPlatform.system}");
in
stdenv.mkDerivation {
  pname = "proton-drive-cli";
  inherit version;

  src = fetchurl {
    url = "https://proton.me/download/drive/cli/${version}/${source.platform}/proton-drive";
    inherit (source) sha512;
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

  meta = {
    description = "Proton's official command-line client for Proton Drive";
    homepage = "https://github.com/ProtonDriveApps/sdk/tree/main/cli";
    license = lib.licenses.mit;
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
    platforms = builtins.attrNames sources;
    mainProgram = "proton-drive";
  };
}
