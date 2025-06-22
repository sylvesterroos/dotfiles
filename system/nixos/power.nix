{ ... }:
{
  services.watt =
    let
      min_freq_mhz = 800;
      tuxedo_pulse_15_gen_2_max_freq_mhz = 4300;
    in
    {
      enable = true;
      settings = {
        charger = {
          governor = "performance";
          battery_charge_thresholds = [
            40
            80
          ];
          min_freq_mhz = min_freq_mhz;
          max_freq_mhz = tuxedo_pulse_15_gen_2_max_freq_mhz;
        };

        battery = {
          governor = "powersave";
          min_freq_mhz = min_freq_mhz;
          max_freq_mhz = builtins.floor (tuxedo_pulse_15_gen_2_max_freq_mhz * 0.75);
        };

        daemon = {
          poll_interval_sec = 5;
          adaptive_interval = true;
          min_poll_interval_sec = 1;
          max_poll_interval_sec = 30;
          throttle_on_battery = true;
          log_level = "Info";
          stats_file_path = "/var/run/watt-stats";
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

  services.thermald.enable = true;
}
