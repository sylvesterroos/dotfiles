# Idle and lid behaviour of the framework. Closing the lid turns the screen
# off; locking and sleep follow the idle timers.
{
  flake.modules.homeManager.framework.programs.plasma = {
    kscreenlocker.timeout = 15;
    powerdevil = {
      AC = {
        dimDisplay.idleTimeout = 15 * 60;
        turnOffDisplay.idleTimeout = 20 * 60;
        autoSuspend = {
          action = "sleep";
          idleTimeout = 60 * 60;
        };
        whenLaptopLidClosed = "turnOffScreen";
      };
      battery = {
        dimDisplay.idleTimeout = 10 * 60;
        turnOffDisplay.idleTimeout = 15 * 60;
        autoSuspend = {
          action = "sleep";
          idleTimeout = 30 * 60;
        };
        whenLaptopLidClosed = "turnOffScreen";
      };
    };
  };
}
