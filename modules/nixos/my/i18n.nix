{
  config,
  lib,
  ...
}:
with lib;
let
  cfg = config.my.i18n;
in
{
  options.my.i18n = {
    enable = mkEnableOption "internationalisation settings" // {
      default = true;
    };
  };

  config = mkIf cfg.enable {
    i18n.defaultLocale = "en_US.UTF-8";

    # en_IE is used as a proxy for en-NL (which doesn't exist as a locale).
    # Provides: DD/MM/YYYY dates, metric measurement, € currency, 24h time.
    i18n.extraLocaleSettings = {
      LC_MESSAGES = "en_IE.UTF-8";
      LC_ADDRESS = "en_IE.UTF-8";
      LC_IDENTIFICATION = "en_IE.UTF-8";
      LC_MEASUREMENT = "en_IE.UTF-8";
      LC_MONETARY = "en_IE.UTF-8";
      LC_NAME = "en_IE.UTF-8";
      LC_NUMERIC = "en_IE.UTF-8";
      LC_PAPER = "en_IE.UTF-8";
      LC_TELEPHONE = "en_IE.UTF-8";
      LC_TIME = "en_IE.UTF-8";
    };
  };
}
