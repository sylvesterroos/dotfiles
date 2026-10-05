{
  pkgs,
  lib,
  config,
  ...
}:
with lib;
let
  cfg = config.my.fonts;

  fontPackages = with pkgs; [
    nerd-fonts.jetbrains-mono
    nerd-fonts.zed-mono
    noto-fonts
    noto-fonts-cjk-sans
    noto-fonts-cjk-serif
    libre-baskerville # Times New Roman alternative
  ];
in
{
  options.my.fonts = {
    enable = mkEnableOption "fonts" // {
      default = true;
    };
  };

  config = mkIf cfg.enable {
    fonts.fontconfig.enable = true;
    home.packages = fontPackages;

    home.activation.flatpakFonts = lib.hm.dag.entryAfter [ "writeBoundary" ] /* bash */ ''
      FONT_TARGET="$HOME/.local/share/fonts"
      if [ -d "$FONT_TARGET" ]; then
        chmod -R u+w "$FONT_TARGET" 2>/dev/null || true
        rm -rf "$FONT_TARGET"
      fi
      mkdir -p "$FONT_TARGET"
      ${concatMapStringsSep "\n" (pkg: ''
        if [ -d "${pkg}/share/fonts" ]; then
          cp -rL ${pkg}/share/fonts/* "$FONT_TARGET"/ 2>/dev/null || true
        fi
      '') fontPackages}
      chmod -R u+w "$FONT_TARGET" 2>/dev/null || true
    '';
  };
}
