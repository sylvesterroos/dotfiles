# One ssh-agent per login session. On the desktops the first SSH use loads the
# passphrase-protected key into it; ksshaskpass supplies the passphrase from
# KWallet, which the login password unlocks.
{
  flake.modules.nixos.desktop = {
    programs.ssh = {
      enableAskPassword = true;
      extraConfig = ''
        AddKeysToAgent yes
      '';
    };
    environment.variables.SSH_ASKPASS_REQUIRE = "prefer";
  };

  flake.modules.homeManager.base = {
    services.ssh-agent.enable = true;
  };
}
