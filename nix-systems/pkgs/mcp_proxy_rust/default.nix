{
  lib,
  stdenv,
  fetchurl,
  autoPatchelfHook,
}: let
  version = "0.2.3";

  sources = {
    "x86_64-linux" = {
      url = "https://github.com/tidewave-ai/mcp_proxy_rust/releases/download/v${version}/mcp-proxy-x86_64-unknown-linux-gnu.tar.gz";
      sha256 = lib.fakeSha256;
    };
    "aarch64-darwin" = {
      url = "https://github.com/tidewave-ai/mcp_proxy_rust/releases/download/v${version}/mcp-proxy-aarch64-apple-darwin.tar.gz";
      sha256 = "sha256-0pKxtkrbdCoi+Ddyl5vT5ZKsXkKg+8sPAK3PFFcHXAQ=";
    };
  };

  platform = "${stdenv.hostPlatform.parsed.cpu.name}-${stdenv.hostPlatform.parsed.kernel.name}";
  source = sources.${platform} or (throw "Unsupported platform: ${platform}");
in
  stdenv.mkDerivation {
    pname = "mcp-proxy-rust";
    inherit version;

    src = fetchurl {
      inherit (source) url sha256;
    };

    nativeBuildInputs = lib.optionals stdenv.isLinux [
      autoPatchelfHook
    ];

    sourceRoot = ".";

    installPhase = ''
      runHook preInstall

      mkdir -p $out/bin
      cp mcp-proxy $out/bin/
      chmod +x $out/bin/mcp-proxy

      runHook postInstall
    '';

    meta = with lib; {
      homepage = "https://github.com/tidewave-ai/mcp_proxy_rust";
      license = licenses.unfree;
      platforms = ["x86_64-linux" "aarch64-darwin"];
    };
  }
