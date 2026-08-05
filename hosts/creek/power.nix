{ ... }:
{
  services.watt = {
    enable = true;
    settings = {
      rule = [
        {
          name = "charger";
          priority = 10;
          "if" = {
            not = "?discharging";
          };
          cpu = {
            governor = {
              "if" = {
                is-governor-available = "performance";
              };
              "then" = "performance";
            };
            turbo = {
              "if" = "?turbo-available";
              "then" = true;
            };
          };
        }
        {
          name = "battery";
          priority = 20;
          "if" = "?discharging";
          cpu = {
            governor = {
              "if" = {
                is-governor-available = "powersave";
              };
              "then" = "powersave";
            };
            turbo = {
              "if" = "?turbo-available";
              "then" = true;
            };
            energy-performance-preference = {
              "if" = {
                is-energy-performance-preference-available = "balance_power";
              };
              "then" = "balance_power";
            };
          };
        }
      ];
    };
  };

  # The nixpkgs module writes /etc/watt.toml but never points the daemon at it;
  # without WATT_CONFIG the daemon falls back to the built-in default config.
  systemd.services.watt.environment.WATT_CONFIG = "/etc/watt.toml";

  services.power-profiles-daemon.enable = false;

  services.tlp = {
    enable = false;
    settings = {
      CPU_BOOST_ON_AC = 1;
      CPU_BOOST_ON_BAT = 0;
      CPU_SCALING_GOVERNOR_ON_AC = "performance";
      CPU_SCALING_GOVERNOR_ON_BAT = "powersave";
    };
  };
}
