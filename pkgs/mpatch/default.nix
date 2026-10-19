{
  lib,
  stdenv,
  fetchurl,
  autoPatchelfHook,
  unzip,
}:
let
  version = "1.7.0";

  sources = {
    "x86_64-linux" = {
      url = "https://github.com/Romelium/mpatch/releases/download/v${version}/mpatch-x86_64-unknown-linux-gnu-v${version}.tar.gz";
      sha256 = "sha256-aFRHY9PDLZinnFfCSDPhfFAHQRTuGQAjVHeRdKH/7TA=";
    };
    "aarch64-linux" = {
      url = "https://github.com/Romelium/mpatch/releases/download/v${version}/mpatch-aarch64-unknown-linux-gnu-v${version}.tar.gz";
      sha256 = "sha256-A3ZQMbxRLKjwKQwkIUTxLygvo366SbOH6nK558Kips8=";
    };
    "aarch64-darwin" = {
      url = "https://github.com/Romelium/mpatch/releases/download/v${version}/mpatch-aarch64-apple-darwin-v${version}.zip";
      sha256 = "sha256-J4A+n6NtGKE4q2xFAVl8F0JGeB4XcY/invzFgG7TQsI=";
    };
  };

  platform = "${stdenv.hostPlatform.parsed.cpu.name}-${stdenv.hostPlatform.parsed.kernel.name}";
  source = sources.${platform} or (throw "Unsupported platform: ${platform}");
in
stdenv.mkDerivation {
  pname = "mpatch";
  inherit version;

  src = fetchurl {
    inherit (source) url sha256;
  };

  nativeBuildInputs =
    lib.optionals stdenv.hostPlatform.isLinux [
      autoPatchelfHook
    ]
    ++ lib.optionals stdenv.hostPlatform.isDarwin [
      unzip
    ];

  buildInputs = lib.optionals stdenv.hostPlatform.isLinux [
    stdenv.cc.cc.lib
  ];

  sourceRoot = ".";

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin
    cp */mpatch $out/bin/
    chmod +x $out/bin/mpatch

    runHook postInstall
  '';

  meta = with lib; {
    description = "A smart, context-aware patch tool that applies diffs using fuzzy matching";
    homepage = "https://github.com/Romelium/mpatch";
    license = licenses.mit;
    platforms = [
      "x86_64-linux"
      "aarch64-linux"
      "aarch64-darwin"
    ];
  };
}
