{lib, ...}: {
  programs.git = {
    userEmail = lib.mkForce "s.roos@nerds.company";
  };
}
