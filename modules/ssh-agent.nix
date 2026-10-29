# One ssh-agent per login session. On the desktops the first SSH use loads the
# passphrase-protected key into it; ksshaskpass supplies the passphrase from
# KWallet, which the login password unlocks.
{
  flake.modules.nixos.desktop =
    { lib, pkgs, ... }:
    let
      ksshaskpass = pkgs.kdePackages.ksshaskpass;
    in
    {
      # Installed so the desktop portal finds its .desktop file and accepts
      # the app ID it registers with.
      environment.systemPackages = [ ksshaskpass ];
      programs.ssh = {
        enableAskPassword = true;
        askPassword = lib.getExe ksshaskpass;
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
