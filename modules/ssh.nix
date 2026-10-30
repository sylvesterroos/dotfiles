{
  flake.modules.nixos.base = {
    services.openssh = {
      enable = true;
      settings = {
        PermitRootLogin = "no";
        PasswordAuthentication = false;
        KbdInteractiveAuthentication = false;
      };
    };

    # Every host in this repository logs in to every other.
    users.users.sylvester.openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIO1bAUV4ZptntILCbS7kuaRQ1stmjr5Ybfrl5T+IN3qu sylvester@creek"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIK3sxjIbkcoYEr5p97JIrVleK3w4SwhZvAUJuAo9L3Mj sylvester@delta"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIE3YVHxGN2K9PW9252C6rIc+eIWUEQILs89GB0NOUdE8 sylvester@bachus"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAII/+z4jZINWL3YC2VIPF5vRlerM+HvihF0M4V4VqnZTy sylvester@framework"
    ];
  };
}
