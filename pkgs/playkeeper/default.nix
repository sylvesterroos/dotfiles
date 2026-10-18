{
  lib,
  buildGoModule,
  buildNpmPackage,
  fetchFromGitHub,
  go_1_27,
  nodejs_24,
}:

let
  version = "0.4.17";

  # The release tag: version is the one knob an update turns (nix-update
  # bumps it; rev follows). The SRI hash pins the content, so a moved tag
  # fails the build instead of silently serving different source.
  rev = "v${version}";

  # The release stamp (scripts/package.sh): Version drives the update
  # checks; Commit identifies the exact build (the tag). Commit and Date
  # are display-only (version.String) — a derived stamp can't go stale.
  ldflags = [
    "-s"
    "-w"
    "-X github.com/CIYAhq/playkeeper/internal/version.Version=${version}"
    "-X github.com/CIYAhq/playkeeper/internal/version.Commit=${rev}"
  ];

  src = fetchFromGitHub {
    owner = "CIYAhq";
    repo = "playkeeper";
    inherit rev;
    hash = "sha256-q3Ovstl19nGZP2iRb/eFMHKuusTAzJFlkmzmFdbkBDg=";
  };

  # The browser UI: npm ci && npm run build, embedded into the binary by
  # web/embed.go (go:embed all:dist*).
  web = buildNpmPackage {
    pname = "playkeeper-web";
    inherit version src;

    sourceRoot = "source/web";

    nodejs = nodejs_24;

    npmDepsHash = "sha256-3VnA4JgX2ykVKfQ5WLoAA4t4iqdFB15G5+bwJIhbsdw=";

    # "build" runs tsc --noEmit && vite build (web/package.json).
    npmBuildScript = "build";

    installPhase = ''
      runHook preInstall

      cp -r dist $out/

      runHook postInstall
    '';
  };
in
buildGoModule {
  pname = "playkeeper";
  inherit version;

  inherit src;

  # go.mod says go 1.26.0; the pinned contributor toolchain is go 1.27.1.
  go = go_1_27;

  inherit ldflags;

  # The repo's .gitignore ignores web/dist, so the filtered GitHub tarball
  # ships web/dist_placeholder.txt and no dist dir: go:embed all:dist*
  # matches the placeholder, fs.Sub("dist") fails, and Dist() returns nil.
  # Put the built UI where the embed pattern expects it.
  postPatch = ''
    rm -f web/dist_placeholder.txt
    cp -r --no-preserve=mode,ownership ${web} web/dist
  '';

  vendorHash = "sha256-OFOVL2pQ03vIuaAYJaV3pB7+/+rXdBK0N7nsFNbyDkw=";

  subPackages = [ "cmd/playkeeper" ];

  # The release stamp sets version.Version in the `go test` binary too
  # (buildGoModule applies ldflags to the check phase), and one
  # usage-stats test asserts an unstamped binary comes from the source;
  # upstream runs its tests unstamped (make test-go). Skip that one test
  # and keep the rest of the suite.
  doCheck = true;
  checkFlags = [ "-skip=^TestTheInstallTakesUsageStatsFromTheEnvironment$" ];

  meta = {
    description = "Self-hosted dashboard for running Minecraft Java servers on a Linux VPS";
    homepage = "https://playkeeper.io";
    license = lib.licenses.agpl3Only;
    mainProgram = "playkeeper";
    platforms = lib.platforms.linux;
    maintainers = [ ];
  };
}
