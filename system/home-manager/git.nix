{ }:

{
  enable = true;

  # TODO:
  # set delta: navigate = true, side-by-side = true, line-numbers = true
  # set merge: conflictStyle = zdiff3
  # view the manual
  delta.enable = true;
  diff-so-fancy.enable = false;

  userEmail = "sylvester@thejoyofcoding.nl";
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

    commit.gpgSign = true;
    tag.gpgSign = true;

    gpg.format = "ssh";
    user.signingKey = "~/.ssh/id_ed25519";
  };
}
