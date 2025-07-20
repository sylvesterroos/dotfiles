{ ... }:

{
  programs.git = {
    enable = true;

    delta = {
      enable = true;
      options = {
        line-numbers = true;
        side-by-side = true;
        navigate = true;
        conflictStyle = "zdiff3";
      };
    };

    userEmail = "sylvester@sylvesterroos.com";
    userName = "Sylvester Roos";

    lfs.enable = true;

    extraConfig = {
      init.defaultBranch = "master";

      core = {
        editor = "flatpak run re.sonny.Commit";

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
    };

    aliases = {
      # Perfect for the daily standup
      yesterday = "log --since='yesterday.midnight' --until='midnight' --all --no-merges --oneline --author=hello@sylvesterroos.com";
    };
  };
}
