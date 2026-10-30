{
  flake.modules.nixos.bachus = {
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
          "creek" = {
            id = "6YSBUTW-CFFQOGH-FKDBVZF-MW7BJDS-BAUB6FE-VMOTHGD-EXICHET-ZEKQNQ2";
            addresses = [ "dynamic" ];
          };
          "framework" = {
            id = "3SEM5NZ-Q6PHHD7-AJHHNW7-M3PEDST-SCNGW6Y-N6E5AIB-KXDOWEM-3XYWWQM";
            addresses = [ "dynamic" ];
          };
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
              "creek"
              "framework"
              "windows-desktop"
              "android"
            ];
            ignorePatterns = [ "(?d).git" ];
          };
          "Documents" = {
            path = "/home/sylvester/Documents";
            devices = [
              "delta"
              "creek"
              "framework"
              "windows-desktop"
            ];
            ignorePatterns = [ "(?d).git" ];
          };
          "Miscellaneous" = {
            path = "/home/sylvester/Miscellaneous";
            devices = [
              "delta"
              "creek"
              "framework"
              "windows-desktop"
            ];
            ignorePatterns = [ "(?d).git" ];
          };
          "Music" = {
            path = "/home/sylvester/Music";
            devices = [
              "delta"
              "creek"
              "framework"
              "windows-desktop"
            ];
            ignorePatterns = [ "(?d).git" ];
          };
          "Pictures" = {
            path = "/home/sylvester/Pictures";
            devices = [
              "delta"
              "creek"
              "framework"
              "windows-desktop"
            ];
            ignorePatterns = [ "(?d).git" ];
          };
          "Videos" = {
            path = "/home/sylvester/Videos";
            devices = [
              "delta"
              "creek"
              "framework"
              "windows-desktop"
            ];
            ignorePatterns = [ "(?d).git" ];
          };
        };
      };
    };
  };
}
