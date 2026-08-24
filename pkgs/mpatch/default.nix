{
  lib,
  stdenv,
  fetchurl,
  autoPatchelfHook,
  unzip,
}:
let
  version = "1.3.5";

  sources = {
    "x86_64-linux" = {
      url = "https://github.com/Romelium/mpatch/releases/download/v${version}/mpatch-x86_64-unknown-linux-gnu-v${version}.tar.gz";
      sha256 = "sha256-+jnV1/6JHWMJJDOWeO/4Gd+VCT7LJbdiqCyskWKmDSU=";
    };
    "aarch64-linux" = {
      url = "https://github.com/Romelium/mpatch/releases/download/v${version}/mpatch-aarch64-unknown-linux-gnu-v${version}.tar.gz";
      sha256 = "sha256-2DYVpYTjlEOR48iZfScwyHsXTDnLMCFof4u2zIFHNWo=";
    };
    "aarch64-darwin" = {
      url = "https://github.com/Romelium/mpatch/releases/download/v${version}/mpatch-aarch64-apple-darwin-v${version}.zip";
      sha256 = "sha256-T2ASLO1mECsH2i9sKZw+MxdZ5B7+4BSxafSETryjDfI=";
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
