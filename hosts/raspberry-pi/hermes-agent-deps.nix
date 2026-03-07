{ pkgs, ... }:
{
  users.users.sylvester = {
    packages = with pkgs; [
      cacert
      ffmpeg
      git
      nodejs_22
      python311
      ripgrep
      uv
    ];
  };
}
