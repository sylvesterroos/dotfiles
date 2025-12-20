{
  pkgs,
  lib,
  config,
  ...
}:
with lib; let
  cfg = config.my.fish;
in {
  options.my.fish = {
    enable =
      mkEnableOption "fish-shell"
      // {
        default = true;
      };
  };

  config = mkIf cfg.enable {
    programs.fish = {
      enable = true;
      shellAliases = {
        ls = "${lib.getExe pkgs.eza} --all --long --group --color=always --group-directories-first --header --icons=auto --git --git-repos-no-status";
        cat = "${lib.getExe pkgs.bat} -pp"; # no line numbers, no pager
      };
      interactiveShellInit = '''';
      shellAbbrs = {
        nsf = {
          expansion = "nix shell nixpkgs#% --command fish";
          position = "command";
          setCursor = true;
        };
        yta-best = "${lib.getExe pkgs.yt-dlp} --add-metadata --extract-audio --audio-format best";
        ytv-best = "${lib.getExe pkgs.yt-dlp} --add-metadata -f bestvideo+bestaudio";
      };
      functions = {
        ns = {
          description = "Expand a nix shell command for a given package";
          body =
            # fish
            ''
              if test (count $argv) -eq 0
                  echo "Usage: expand_nix <package>"
                  return 1
              end
              set pkg $argv[1]
              # replace the entire buffer with the expanded nix shell command
              commandline -r "nix shell nixpkgs#$pkg -c $pkg"
            '';
        };

        mkfile = {
          body =
            # fish
            ''
              if test "$argv[1]" = "--help"
                  echo "Creates a new file and any necessary parent directories."
                  echo "Usage: mkfile path/to/new/file.txt"
                  return 0
              end

              if test (count $argv) = 0
                  echo "mkfile: missing directory and/or file operand"
                  echo "Try 'mkfile --help' for more information."
                  return 1
              end

              mkdir -p (dirname $argv[1]) && touch $argv[1]
            '';
        };

        prune-direnv-gcroots = {
          description = ''
            Finds all `.direnv` and `.devenv` gcroots and removes them. Additionally runs `direnv deny` in the associated projects.

            Useful when you have a bunch of scattered Devenv projects that are causing the nix store to balloon.
          '';
          body =
            # fish
            ''
              function contains_direnv_or_devenv
                  set path $argv[1]
                  if string match -q -r '/\.direnv/|/\.devenv/' $path
                      return 0
                  else
                      return 1
                  end
              end

              # Function: Walk up from the given path until we find a directory named .direnv or .devenv,
              # then return its parent directory (the project root).
              function find_env_project_root
                  set path $argv[1]
                  while test "$path" != "/"
                      # If the current directory is .direnv or .devenv, return its parent
                      if test (basename $path) = ".direnv" -o (basename $path) = ".devenv"
                          echo (dirname $path)
                          return 0
                      end
                      # Move up one directory
                      set path (dirname $path)
                  end
                  return 1
              end

              set deny_dirs
              set symlinks_to_remove

              # Loop through all symlinks in /nix/var/nix/gcroots/auto/
              for symlink in (${lib.getExe pkgs.fd} -t l . /nix/var/nix/gcroots/auto/)
                  # Get the symlink target (single follow)
                  set target (readlink $symlink)
                  # Resolve relative symlink targets to absolute paths
                  if test (string sub -l 1 -- $target) = "/"
                      set resolved_target $target
                  else
                      set resolved_target (realpath (dirname $symlink)/$target)
                  end

                  # If the resolved target contains .direnv or .devenv, find the project root
                  if contains_direnv_or_devenv $resolved_target
                      set parent_dir (find_env_project_root $resolved_target)
                      if test -n "$parent_dir"
                          set deny_dirs $deny_dirs $parent_dir
                          set symlinks_to_remove $symlinks_to_remove $symlink
                      end
                  end
              end

              # Deduplicate the list of project roots
              set deny_dirs (printf "%s\n" $deny_dirs | sort -u)

              # Run direnv deny in each unique project root
              for d in $deny_dirs
                  echo "Running direnv deny in $d"
                  pushd $d
                  direnv deny
                  popd
              end

              echo "Total direnvs denied: "(count $deny_dirs)

              # Remove the gcroot symlinks
              for s in $symlinks_to_remove
                  echo "Removing gcroot symlink $s pointing to $(readlink $s)"
                  sudo rm $s
              end

              echo "Total gcroot symlinks removed: "(count $symlinks_to_remove)
            '';
        };

        ###
        # Git functions
        ###

        gw = {
          description = "Navigate to a git worktree using fzf";
          body = let
            git = lib.getExe pkgs.git;
            fzf = lib.getExe pkgs.fzf;
          in
            # fish
            ''
              # Check if inside git worktree
              ${git} rev-parse --is-inside-git-dir >/dev/null 2>&1
              if test $status -ne 0
                  echo "Not in a git directory"
                  return 1
              end

              # Get worktree list, filter out (bare), extract paths, use fzf for selection
              set -l selected (
                  ${git} worktree list |
                  grep -v "(bare)" |
                  ${fzf} --height 40% --border --prompt="Select worktree: " --query="$argv[1]" |
                  awk '{print $1}'
              )

              # If a worktree was selected, navigate to it
              if test -n "$selected"
                  cd "$selected"
              else
                  echo "No worktree selected."
              end
            '';
        };
      };
    };
  };
}
