# General tools that agents seem to enjoy.
let
  packages =
    pkgs: with pkgs; [
      # Search and navigation
      eza
      fd
      ripgrep
      sd
      tree

      # Text and data
      bat
      diffutils
      gawk
      jq
      moreutils
      patch
      yq

      # Archives and compression
      gnutar
      p7zip
      unzip
      zip
      zstd

      # Network and remote work
      curl
      netcat
      openssh
      rsync
      socat
      wget
      xh

      # System inspection
      dust
      file
      less
      lsof
      ncdu
      procps

      # Version control and automation
      expect
      gh

      # Scripting and measurement
      openssl
    ];
in
{
  flake.modules.homeManager.base =
    { pkgs, ... }:
    {
      home.packages = packages pkgs;
    };

  flake.modules.nixos.without-home-manager =
    { pkgs, ... }:
    {
      users.users.sylvester.packages = packages pkgs;
    };
}
