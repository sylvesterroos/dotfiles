{
  flake.modules.nixos.bachus = {
    services.fail2ban = {
      enable = true;
    };
  };
}
