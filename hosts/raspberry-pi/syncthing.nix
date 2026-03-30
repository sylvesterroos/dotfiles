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
        "macbook" = {
          id = "MUZ2AKA-7YSWPBY-IJIV6DE-2JHBXXY-XNAFOZW-UUFZEQW-YHNMXJR-Y5UCUQJ";
          addresses = [ "dynamic" ];
        };
        # "android" = {
        #   id = "DDDDDDD-...";
        #   addresses = [ "dynamic" ];
        # };
      };

      folders = {
        "PARA" = {
          path = "/home/sylvester/PARA";
          devices = [
            "delta"
            "windows-desktop"
            "macbook"
            # "android"
          ];
        };
      };
    };
  };
}
