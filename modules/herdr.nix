{ config, inputs, ... }:
let
  herdrTui = pkgs: inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.herdr;
  hosts = builtins.attrNames config.configurations.nixos;
in
{
  flake.modules.nixos.bachus =
    { pkgs, ... }:
    {
      users.users.sylvester.packages = [ (herdrTui pkgs) ];
    };

  flake.modules.homeManager.desktop =
    {
      lib,
      osConfig,
      pkgs,
      ...
    }:
    let
      herdr = lib.getExe (herdrTui pkgs);
      # Every other host as a saved SSH machine, so the sidebar lists its
      # workspaces and agents next to Local. Herdr requires a profile id of 32
      # lowercase hex characters; a digest of the host name keeps it stable.
      machines = map (host: {
        id = builtins.substring 0 32 (builtins.hashString "sha256" host);
        label = host;
        target = host;
        session = "default";
        enabled = true;
      }) (lib.remove osConfig.networking.hostName hosts);
      # Pick a Hermes profile, then open it as a tab in the "~" workspace,
      # creating that workspace on first use.
      hermesTab = pkgs.writers.writeNu "herdr-hermes-tab" ''
        let profiles = ["default"] ++ (ls ~/.hermes/profiles | where type == dir | get name | path basename)
        let profile = $profiles | input list --fuzzy "Hermes profile"
        if $profile == null { return }
        let home = ^${herdr} workspace list | from json | get result.workspaces | where label == "~"
        let tab = if ($home | is-empty) {
          ^${herdr} workspace create --cwd $env.HOME --label "~" --focus | from json | get result
        } else {
          ^${herdr} tab create --workspace $home.0.workspace_id --cwd $env.HOME --focus | from json | get result
        }
        ^${herdr} tab rename $tab.tab.tab_id $profile | ignore
        ^${herdr} workspace focus $tab.tab.workspace_id | ignore
        ^${herdr} pane run $tab.root_pane.pane_id $"hermes -p ($profile)" | ignore
      '';
    in
    {
      xdg.stateFile."herdr/client/endpoints.json".text = builtins.toJSON {
        version = 1;
        ssh = machines;
      };

      programs.herdr = {
        enable = true;
        package = herdrTui pkgs;
        settings = {
          onboarding = false;
          ui = {
            status_indicators = "symbols";
            toast.delivery = "system";
            sidebar.agents.rows = [
              [
                "state_icon"
                "machine"
                "workspace"
                "tab"
              ]
              [ "agent" ]
              [ "state_text" ]
            ];
          };
          keys.command = [
            {
              key = "prefix+alt+h";
              type = "popup";
              command = "${hermesTab}";
              description = "hermes in ~ (pick profile)";
              width = 40;
              height = 10;
            }
          ];
        };
      };
    };
}
