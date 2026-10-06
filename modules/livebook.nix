{
  flake.modules.nixos.livebook =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    with lib;
    let
      # Libraries that need to be available to the dynamic linker at runtime
      sharedLibraries = with pkgs; [
        # C++ standard library compatibility
        libgcc.lib
      ];

      setupSharedLibraries = config.programs.nix-ld.enable;

      nixLdEnvVars = rec {
        # Library search path for the dynamic linker
        NIX_LD_LIBRARY_PATH = lib.makeLibraryPath sharedLibraries;

        # Path to the dynamic linker itself
        NIX_LD = lib.fileContents "${pkgs.stdenv.cc}/nix-support/dynamic-linker";

        # Fallback for executables that don't use NIX_LD
        LD_LIBRARY_PATH = NIX_LD_LIBRARY_PATH;
      };
    in
    {
      services.livebook = {
        enableUserService = true;
        package = pkgs.livebook;

        environment = {
          LIVEBOOK_PORT = 20123;
          LIVEBOOK_TOKEN_ENABLED = false;
        }
        // (optionalAttrs setupSharedLibraries nixLdEnvVars);

        # Build tools and executables needed during compilation
        extraPackages = with pkgs; [
          gcc

          # Build systems
          gnumake
          cmake

          # Rust toolchain
          cargo
        ];
      };
    };
}
