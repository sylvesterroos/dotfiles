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
        whenLaptopLidClosed = "doNothing";
        inhibitLidActionWhenExternalMonitorConnected = false;
      };
      battery = {
        dimDisplay.idleTimeout = 10 * 60;
        turnOffDisplay.idleTimeout = 15 * 60;
        autoSuspend = {
          action = "sleep";
          idleTimeout = 30 * 60;
        };
        whenLaptopLidClosed = "doNothing";
        inhibitLidActionWhenExternalMonitorConnected = false;
      };
    };
  };
}
