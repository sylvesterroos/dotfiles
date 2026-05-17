{
  pkgs,
  lib,
  inputs,
  config,
  ...
}:
with lib;
let
  cfg = config.my.git;
in
{
  options.my.git = {
    enable = mkEnableOption "git" // {
      default = true;
    };
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      gitu
      jjui
    ];

    programs.jujutsu = {
      enable = true;
    };

    programs.difftastic = {
      enable = true;
      git = {
        enable = true;
        diffToolMode = true;
      };
    };

    programs.lazygit = {
      enable = true;
    };

    programs.git = {
      enable = true;

      settings = {
        user = {
          email = "sylvester@sylvesterroos.com";
          name = "Sylvester Roos";
        };

        init.defaultBranch = "master";

        core = {
          autocrlf = "input"; # convert CRLF to LF on commit
        };

        commit.verbose = true;

        push.autoSetupRemote = true;

        rerere.enabled = true;
        merge.conflictStyle = "zdiff3";

        # Sign all commits using ssh key
        commit.gpgSign = true;
        tag.gpgSign = true;
        gpg.format = "ssh";
        # should contain "* $(cat ~/.ssh/id_ed25519.pub)"
        gpg.ssh.allowedSignersFile = "~/.ssh/allowed_signers";
        user.signingkey = "~/.ssh/id_ed25519.pub";

        aliases = {
          # Perfect for the daily standup
          yesterday = "log --since='yesterday.midnight' --until='midnight' --all --no-merges --oneline --author=sylvester@sylvesterroos.com";
        };
      };

      lfs.enable = true;
    };
  };
}
