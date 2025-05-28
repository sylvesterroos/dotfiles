{ ... }:
{
  services.superfreq = {
    enable = true;
    settings = {
      charger = {
        governor = "performance";
        turbo = "auto";
        enable_auto_turbo = true;
        turbo_auto_settings = {
          load_threshold_high = 70.0;
          load_threshold_low = 30.0;
          temp_threshold_high = 75.0;
          initial_turbo_state = false;
        };
        epp = "performance";
        epb = "balance_performance";
        platform_profile = "performance";
        battery_charge_thresholds = [
          40
          80
        ];
      };

      battery = {
        governor = "powersave";
        turbo = "auto";
        enable_auto_turbo = true;
        turbo_auto_settings = {
          load_threshold_high = 80.0;
          load_threshold_low = 40.0;
          temp_threshold_high = 70.0;
          initial_turbo_state = false;
        };
        epp = "power";
        epb = "balance_power";
        platform_profile = "low-power";
      };

      daemon = {
        poll_interval_sec = 5;
        adaptive_interval = true;
        min_poll_interval_sec = 1;
        max_poll_interval_sec = 30;
        throttle_on_battery = true;
        log_level = "Info";
        stats_file_path = "/var/run/superfreq-stats";
      };

      power_supply_ignore_list = {
        mouse_battery = "hidpp_battery_0";
      };
    };
  };

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

  services.thermald.enable = false;
}
