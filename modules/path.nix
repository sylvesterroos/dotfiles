# ~/.local/bin on sylvester's PATH.
{
  flake.modules.homeManager.base = {
    home.sessionPath = [ "$HOME/.local/bin" ];
  };

  flake.modules.nixos.without-home-manager = {
    environment.loginShellInit = ''
      if [ "$USER" = 'sylvester' ]; then
        PATH="$HOME/.local/bin''${PATH:+:$PATH}"
        export PATH
      fi
    '';
  };
}
