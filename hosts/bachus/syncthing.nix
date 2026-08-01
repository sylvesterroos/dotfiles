{
  services.syncthing = {
    enable = true;
    user = "sylvester";
    group = "users";
    dataDir = "/home/sylvester/.local/share/syncthing";
    configDir = "/home/sylvester/.config/syncthing";
    openDefaultPorts = true;
    extraFlags = [ ];
    guiAddress = "0.0.0.0:8384";
    overrideDevices = true;
    overrideFolders = true;

    settings = {
      options = {
        relaysEnabled = false;
        globalAnnounceEnabled = false;
        localAnnounceEnabled = false;
      };

      devices = {
        "delta" = {
          id = "RIPWL5Z-TW2KRNY-D37ODDG-6GVWNSM-BB5BQ5N-L4GF5N3-KETQZGC-XONJ5AY";
          addresses = [ "dynamic" ];
        };
        # "creek" = {
        #   id = "BBBBBBB-...";
        #   addresses = [ "dynamic" ];
        # };
        "windows-desktop" = {
          id = "ICJG2JE-NOR37L7-NETFILO-A6DSKEU-JZ2RW2J-FQVWNJV-ELRGLCV-GG7SQQR";
          addresses = [ "dynamic" ];
        };
        "android" = {
          id = "SVXC6BU-JPAQG52-FRSYVFQ-6KOZOEK-P6ROCLJ-KR6LACX-HGKGGGZ-SKLYLQJ";
          addresses = [ "dynamic" ];
        };
      };

      folders = {
        "PARA" = {
          path = "/home/sylvester/PARA";
          devices = [
            "delta"
            "windows-desktop"
            "android"
          ];
        };
        "agent-vault" = {
          path = "~/.local/share/agent-vault";
          devices = [
            "delta"
            "windows-desktop"
            "android"
          ];
        };
        "Documents" = {
          path = "/home/sylvester/Documents";
          devices = [
            "delta"
            "windows-desktop"
          ];
        };
        "Miscellaneous" = {
          path = "/home/sylvester/Miscellaneous";
          devices = [
            "delta"
            "windows-desktop"
          ];
        };
        "Music" = {
          path = "/home/sylvester/Music";
          devices = [
            "delta"
            "windows-desktop"
          ];
        };
        "Pictures" = {
          path = "/home/sylvester/Pictures";
          devices = [
            "delta"
            "windows-desktop"
          ];
        };
        "Projects" = {
          path = "/home/sylvester/Projects";
          devices = [
            "delta"
            "windows-desktop"
          ];
        };
        "Videos" = {
          path = "/home/sylvester/Videos";
          devices = [
            "delta"
            "windows-desktop"
          ];
        };
      };
    };
  };
}
