# Project Zomboid dedicated server, run by pznix: steamcmd installs and updates
# the game and its Workshop mods on every start and at 04:00 daily.
#
# Friends join over the headscale tailnet at bachus.<headscale domain>:16261.
# The userspace headscaled hands their UDP to 127.0.0.1, so the server needs
# no open firewall port; the headscale policy grants the game ports.
{ inputs, ... }:
{
  flake.modules.nixos.bachus =
    { config, ... }:
    {
      imports = [ inputs.pznix.nixosModules.default ];

      sops.secrets."zomboid/admin-password".owner = "pzserver-zomboid";
      sops.secrets."zomboid/rcon-password".owner = "pzserver-zomboid";

      services.pznix.servers.zomboid = {
        adminPasswordFile = config.sops.secrets."zomboid/admin-password".path;
        # RCON carries the in-game warnings before the daily update restart.
        rconPasswordFile = config.sops.secrets."zomboid/rcon-password".path;
        openFirewall = false;

        # A cgroup ceiling above the JVM heap that PZ sets itself (-Xmx in
        # ProjectZomboid64.json).
        memoryLimit = "12G";

        workshopItems = [
          "3464551542" # Functional Car Lift
          "3728891451" # Automatic Lights
          "2313387159" # Better Sorting
          "3426448380" # Immersive Suicide
          "2956146279" # Rain Cleans Blood
        ];

        extraIniSettings = {
          PVP = "false";
          Public = "false";
          # Sleeping fast-forwards time once every player online is asleep,
          # at FastForwardMultiplier (default 40x).
          SleepAllowed = "true";
        };
      };
    };
}
