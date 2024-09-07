{ ... }:
{
  enable = true;
  diff-so-fancy.enable = true;
  userEmail = "sylvester@thejoyofcoding.nl";
  userName = "Sylvester Roos";
  extraConfig = {
    init.defaultBranch = "master";
    core = {
      editor = "flatpak run re.sonny.Commit";
      autocrlf = "input"; # convert CRLF to LF on commit
    };
  };
  signing = {
    key = null; # use GPG key with same email as userEmail
    signByDefault = true;
  };
}
