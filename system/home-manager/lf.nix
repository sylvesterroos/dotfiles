{ pkgs, ... }:

{
  # add icons to the lf XDG_CONFIG directory
  xdg.configFile."lf/icons".source = ./icons;

  programs.lf = {
    enable = true;

    # multi-line strings to avoid escaping double and single quotes
    commands = {
      editor-open = ''$$EDITOR $f'';
      mkdir = ''
        ''${{
          printf "Directory name: "
          read DIR
          mkdir $DIR
        }}
      '';
    };

    keybindings = {
      # means double-quote key
      "\\\"" = "";
      o = "";
      c = "mkdir";
      "." = "set hidden!";
      "`" = "mark-load";
      "\\'" = "mark-load";
      "<enter>" = "open";

      "g~" = "cd";
      gh = "cd";
      "g/" = "/";

      ee = "editor-open";
      V = ''${pkgs.bat}/bin/bat --paging=always "$f"'';

      # ...
    };

    settings = {
      preview = true;
      hidden = true;
      drawbox = true;
      icons = true;
      ignorecase = true;
    };

    extraConfig =
      let
        # Script to handle file preview functionality
        # Takes file path and dimensions (w,h,x,y) as arguments
        previewer = pkgs.writeShellScriptBin "pv.sh" ''
          file=$1
          w=$2
          h=$3
          x=$4
          y=$5

          # If file is an image, display it using kitty's image protocol
          if [[ "$( ${pkgs.file}/bin/file -Lb --mime-type "$file")" =~ ^image ]]; then
              ${pkgs.kitty}/bin/kitty +kitten icat --silent --stdin no --transfer-mode file --place "''${w}x''${h}@''${x}x''${y}" "$file" < /dev/null > /dev/tty
              exit 1
          fi

          # For non-image files, use pistol to preview
          # pistol is a general-purpose file previewer
          # this is an alternative to creating a preview script for every file type
          ${pkgs.pistol}/bin/pistol "$file"
        '';

        # Script to clean up image previews from terminal
        cleaner = pkgs.writeShellScriptBin "clean.sh" ''
          ${pkgs.kitty}/bin/kitty +kitten icat --clear --stdin no --silent --transfer-mode file < /dev/null > /dev/tty
        '';
      in
      ''
        set cleaner ${cleaner}/bin/clean.sh
        set previewer ${previewer}/bin/pv.sh
      '';
  };
}
