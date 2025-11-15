{
  pkgs,
  lib,
  ...
}: {
  home.packages = with pkgs; [
    gitu
    jjui
  ];

  programs.jujutsu = {
    enable = true;
  };

  programs.delta = {
    enable = true;
    enableGitIntegration = true;
    options = {
      line-numbers = true;
      side-by-side = true;
      navigate = true;
      conflictStyle = "zdiff3";
    };
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

      # Sign all commits using ssh key
      commit.gpgSign = true;
      tag.gpgSign = true;
      gpg.format = "ssh";
      # should contain "* $(cat ~/.ssh/id_ed25519.pub)"
      gpg.ssh.allowedSignersFile = "~/.ssh/allowed_signers";
      user.signingkey = "~/.ssh/id_ed25519.pub";

      aliases = {
        # Perfect for the daily standup
        yesterday = "log --since='yesterday.midnight' --until='midnight' --all --no-merges --oneline --author=hello@sylvesterroos.com";
      };
    };

    lfs.enable = true;
  };
}
