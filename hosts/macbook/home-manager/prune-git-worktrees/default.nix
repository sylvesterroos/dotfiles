{ pkgs, lib, ... }:
let
  nuWrapperArgs = {
    makeWrapperArgs = [
      "--prefix"
      "PATH"
      ":"
      "${lib.makeBinPath [ pkgs.git ]}"
    ];
  };

  prune-git-worktrees = pkgs.writers.writeNuBin "prune-git-worktrees" nuWrapperArgs (
    builtins.readFile ./prune-git-worktrees.nu
  );
in
{
  home.packages = [
    prune-git-worktrees
  ];
}
