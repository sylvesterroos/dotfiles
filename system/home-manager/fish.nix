{ ... }:

{
  programs.fish = {
    enable = true;
    shellAliases = {
      ls = ''
        eza \
            --all \
            --long \
            --grid \
            --group-directories-first \
            --header \
            --icons=auto \
            --git \
            --git-repos-no-status
      '';

      cat = "bat -pp"; # no line numbers, no pager

      ssh-keygen-ed25519 = "ssh-keygen -t ed25519 -C (whoami)@(uname -n)";
    };
    interactiveShellInit = '''';
    shellAbbrs = {
      update = "nix flake update --commit-lock-file --flake $HOME/.dotfiles/system";
      rebuild = "sudo nixos-rebuild --flake path:$HOME/.dotfiles/system#odysseus";

      nsh = "nix-shell --run fish";

      yta-best = "yt-dlp --add-metadata --extract-audio --audio-format best";
      ytv-best = "yt-dlp --add-metadata -f bestvideo+bestaudio";
    };
    functions = {
      ghcs = {
        body = # fish
          ''
            set -l TARGET shell
            set -l GH_DEBUG $GH_DEBUG
            set -l GH_HOST $GH_HOST
            set -l USAGE "Wrapper around `gh copilot suggest` to suggest a command based on a natural language description of the desired output effort.
            Supports executing suggested commands if applicable.
            USAGE
              $_ [flags] <prompt>
            FLAGS
              -d, --debug              Enable debugging
              -h, --help               Display help usage
                  --hostname           The GitHub host to use for authentication
              -t, --target target      Target for suggestion; must be shell, gh, git
                                       default: \"$TARGET\"
            EXAMPLES
            - Guided experience
              \$ $_
            - Git use cases
              \$ $_ -t git \"Undo the most recent local commits\"
              \$ $_ -t git \"Clean up local branches\"
              \$ $_ -t git \"Setup LFS for images\"
            - Working with the GitHub CLI in the terminal
              \$ $_ -t gh \"Create pull request\"
              \$ $_ -t gh \"List pull requests waiting for my review\"
              \$ $_ -t gh \"Summarize work I have done in issues and pull requests for promotion\"
            - General use cases
              \$ $_ \"Kill processes holding onto deleted files\"
              \$ $_ \"Test whether there are SSL/TLS issues with github.com\"
              \$ $_ \"Convert SVG to PNG and resize\"
              \$ $_ \"Convert MOV to animated PNG\""

            set -l options d/debug h/help 'hostname=' 't/target='
            argparse -n ghcs $options -- $argv
            or return

            if set -q _flag_debug
                set GH_DEBUG api
            end

            if set -q _flag_help
                echo $USAGE
                return 0
            end

            if set -q _flag_hostname
                set GH_HOST $_flag_hostname
            end

            if set -q _flag_target
                set TARGET $_flag_target
            end

            set -l TMPFILE (mktemp -t gh-copilotXXXXXX)
            function cleanup --on-event fish_exit
                rm -f $TMPFILE
            end

            if env GH_DEBUG=$GH_DEBUG GH_HOST=$GH_HOST gh copilot suggest -t $TARGET $argv --shell-out $TMPFILE
                if test -s $TMPFILE
                    set -l FIXED_CMD (cat $TMPFILE)
                    echo
                    eval $FIXED_CMD
                    history merge
                end
            else
                return 1
            end
          '';
      };

      ghce = {
        body = # fish
          ''
            set -l GH_DEBUG $GH_DEBUG
            set -l GH_HOST $GH_HOST
            set -l USAGE "Wrapper around `gh copilot explain` to explain a given input command in natural language.
            USAGE
              $_ [flags] <command>
            FLAGS
              -d, --debug      Enable debugging
              -h, --help       Display help usage
                  --hostname   The GitHub host to use for authentication
            EXAMPLES
            # View disk usage, sorted by size
            \$ $_ 'du -sh | sort -h'
            # View git repository history as text graphical representation
            \$ $_ 'git log --oneline --graph --decorate --all'
            # Remove binary objects larger than 50 megabytes from git history
            \$ $_ 'bfg --strip-blobs-bigger-than 50M'"

            set -l options d/debug h/help 'hostname='
            argparse -n ghce $options -- $argv
            or return

            if set -q _flag_debug
                set GH_DEBUG api
            end

            if set -q _flag_help
                echo $USAGE
                return 0
            end

            if set -q _flag_hostname
                set GH_HOST $_flag_hostname
            end

            env GH_DEBUG=$GH_DEBUG GH_HOST=$GH_HOST gh copilot explain $argv
          '';
      };
    };
  };
}
