{
  lib,
  rustPlatform,
  fetchFromGitHub,
  pkg-config,
  cmake,
  nasm,
  alsa-lib,
  libxkbcommon,
  libx11,
  libxcursor,
  libxi,
  libxrandr,
  libxcb,
  wayland,
  vulkan-loader,
  libGL,
}:
rustPlatform.buildRustPackage {
  pname = "anima-engine";
  version = "1.2.0";

  src = fetchFromGitHub {
    owner = "Alexandru2984";
    repo = "animaEngine";
    tag = "v1.2.0";
    hash = "sha256-4wYNflxBJA3uTBjYQQurpRaA8Lbgf7ehB9s5cvvr9Gw=";
  };
  cargoHash = "sha256-Kj2iBZGJ/Dc8Vw5xLDmwTbzll7uwII/shvJF2E/iVLk=";

  nativeBuildInputs = [
    pkg-config
    cmake
    nasm
  ];
  buildInputs = [
    alsa-lib
    libxkbcommon
  ];
  cargoTestFlags = [ "--lib" ];

  postInstall = ''
    mv $out/bin/anima_engine $out/bin/anima-engine
    install -Dm644 data/com.animaengine.Anima.desktop \
      $out/share/applications/com.animaengine.Anima.desktop
    install -Dm644 data/anima-engine.svg \
      $out/share/icons/hicolor/scalable/apps/anima-engine.svg
    install -Dm644 data/com.animaengine.Anima.metainfo.xml \
      $out/share/metainfo/com.animaengine.Anima.metainfo.xml
  '';

  # winit and wgpu load these with dlopen at runtime, so the linker never records them.
  postFixup = ''
    patchelf --add-rpath ${
      lib.makeLibraryPath [
        libxkbcommon
        libx11
        libxcursor
        libxi
        libxrandr
        libxcb
        wayland
        vulkan-loader
        libGL
      ]
    } $out/bin/anima-engine
  '';

  meta = {
    description = "Animated desktop overlay engine with characters and sprites";
    homepage = "https://github.com/Alexandru2984/animaEngine";
    license = lib.licenses.mit;
    mainProgram = "anima-engine";
    platforms = lib.platforms.linux;
  };
}
