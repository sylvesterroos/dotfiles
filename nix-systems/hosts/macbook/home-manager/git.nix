{ lib, ... }:
{
  programs.git = {
    settings = {
      user = {
        email = lib.mkForce "s.roos@nerds.company";
      };

      aliases = {
        # Perfect for the daily standup
        yesterday = lib.mkForce "log --since='yesterday.midnight' --until='midnight' --all --no-merges --oneline --author=s.roos@nerds.company";
      };
    };
  };

  home.sessionVariables = {
    GIT_EDITOR = "zed --wait";
  };
}
