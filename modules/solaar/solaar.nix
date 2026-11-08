{
  flake.modules.nixos.desktop.programs.solaar.enable = true;

  flake.modules.homeManager.desktop =
    {
      lib,
      osConfig,
      pkgs,
      ...
    }:
    let
      solaar = osConfig.programs.solaar.package;
      divertGestureButton = pkgs.writers.writePython3 "divert-gesture-button" {
        libraries = [ pkgs.python3Packages.pyyaml ];
        flakeIgnore = [ "E501" ];
      } (builtins.readFile ./divert_gesture_button.py);
      rules = pkgs.writeText "solaar-rules.yaml" ''
        %YAML 1.3
        ---
        - MouseGesture: [Mouse Left]
        - KeyPress: [[Control_L, Super_L, Right], click]
        ...
        ---
        - MouseGesture: [Mouse Right]
        - KeyPress: [[Control_L, Super_L, Left], click]
        ...
        ---
        - MouseGesture: [Mouse Up]
        - KeyPress: [[Super_L, w], click]
        ...
        ---
        - MouseGesture: [Mouse Down]
        - KeyPress: [[Super_L, d], click]
        ...
      '';
    in
    {
      xdg.configFile."solaar/rules.yaml".source = rules;

      # plasma-manager's panels route rebuilds the whole appletsrc, so patch the
      # tray applet instead. hiddenItems keeps the icon in the popup
      programs.plasma.startup.desktopScript."solaar-tray-icon" = {
        text = ''
          var id = "indicator-solaar";

          panels().forEach(function (panel) {
            panel.widgets("org.kde.plasma.systemtray").forEach(function (tray) {
              tray.currentConfigGroup = ["General"];
              var current = tray.readConfig("hiddenItems", "");
              var items = current === "" ? [] : current.split(",");
              if (items.indexOf(id) === -1) {
                items.push(id);
                tray.writeConfig("hiddenItems", items.join(","));
              }
            });
          });
        '';
      };

      systemd.user.services.solaar = {
        Unit = {
          Description = "Solaar";
          PartOf = [ "graphical-session.target" ];
          After = [ "graphical-session.target" ];
          X-Restart-Triggers = [ "${rules}" ];
        };
        Service = {
          ExecStartPre = "${divertGestureButton} ${solaar.version}";
          ExecStart = "${lib.getExe solaar} --window=hide";
          Restart = "on-failure";
        };
        Install.WantedBy = [ "graphical-session.target" ];
      };
    };
}
