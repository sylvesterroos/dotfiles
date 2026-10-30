{ inputs, ... }:
let
  herdrTui = pkgs: inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.herdr;
in
{
  flake.modules.nixos.bachus =
    { pkgs, ... }:
    {
      users.users.sylvester.packages = [ (herdrTui pkgs) ];
    };

  flake.modules.homeManager.desktop =
    { lib, pkgs, ... }:
    let
      herdr = lib.getExe (herdrTui pkgs);
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
