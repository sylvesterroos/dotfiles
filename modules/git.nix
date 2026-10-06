{
  flake.modules.homeManager.base =
    { pkgs, ... }:
    {
      home.packages = with pkgs; [
        jjui
      ];

      programs.jujutsu = {
        enable = true;
      };

      programs.difftastic = {
        enable = true;
        git = {
          enable = true;
          mode = "both";
        };
      };

      programs.lazygit = {
        enable = true;
      };

      programs.git = {
        enable = true;

        settings = {
          alias = {
            # Perfect for the daily standup
            yesterday = "log --since='yesterday.midnight' --until='midnight' --all --no-merges --oneline --author=sylvester@sylvesterroos.com";
            b = "blame -w -C -C -C";
          };

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
        };

        lfs.enable = true;
      };
    };
}
