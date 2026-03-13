{ pkgs, ... }:
{
  users.users.sylvester = {
    packages = with pkgs; [
      cacert
      ffmpeg
      git
      nodejs_22
      playwright-driver.browsers
      python311
      ripgrep
      uv
    ];
  };

  # For now manually override the playwright version in package.json to match the nixpkgs browser revision
  environment.sessionVariables = {
    PLAYWRIGHT_BROWSERS_PATH = "${pkgs.playwright-driver.browsers}";
    PLAYWRIGHT_SKIP_VALIDATE_HOST_REQUIREMENTS = "true";
  };
}
