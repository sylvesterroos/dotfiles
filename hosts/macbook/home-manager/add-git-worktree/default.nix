{ pkgs, lib, ... }:
let
  nuWrapperArgs = {
    makeWrapperArgs = [
      "--prefix"
      "PATH"
      ":"
      "${lib.makeBinPath [ pkgs.git pkgs.fzf ]}"
    ];
  };

  add-git-worktree = pkgs.writers.writeNuBin "add-git-worktree" nuWrapperArgs (
    builtins.readFile ./add-git-worktree.nu
  );
in
{
  home.packages = [
    add-git-worktree
  ];
}
