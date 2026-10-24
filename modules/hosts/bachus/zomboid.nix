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
          "3814073243" # Zombie Visibility Fix + Stair-O-Vision
          # The original Common Sense (2875848298) stops B42 from loading the
          # world ("Fluid not found: Alcohol"). This is its maintained B42 fork;
          # never enable both.
          "3717968421" # Common Sense B42.20 - Community Compatibility Fix
          # Puts the "Alcohol" fluid back for any mod recipe still asking for it.
          "3683880154" # Alcohol Fluid Fix [B42]
          # The maintained B42 fork of Ladders!? (2737665235); never enable both.
          "3629835761" # Ladders?! B42.20 SP/MP (Unofficial)
        ];

        # The Ladders fork ships one mod ID per game version; Ladders42204 is
        # the current one, and these two are older builds kept for old saves.
        excludeMods = [
          "Ladders42131"
          "Ladders4220"
        ];

        extraIniSettings = {
          PVP = "false";
          Public = "false";
          # Accept any headscale member on first join; each creates an account.
          Open = "true";
          # Linux clients get false kicks from this check (PZwiki warns of a Linux bug).
          DoLuaChecksum = "false";
          # Sleeping fast-forwards time once every player online is asleep,
          # at FastForwardMultiplier (default 40x).
          SleepAllowed = "true";
        };
      };
    };
}
