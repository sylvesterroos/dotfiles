{
  config,
  lib,
  inputs,
  ...
}:
{
  imports = [ inputs.hermes-agent.nixosModules.default ];

  # So we can use the TUI
  environment.variables.HERMES_HOME = "${config.services.hermes-agent.stateDir}/.hermes";

  services.hermes-agent = {
    enable = true;

    # Model
    settings = {
      model = {
        base_url = "https://inference-api.nousresearch.com/v1";
        default = "minimax/minimax-m2.5";
        provider = "nous";
      };
      toolsets = [ "all" ];
      max_turns = 70;
      terminal = {
        backend = "local";
        cwd = ".";
        timeout = 180;
      };
      compression = {
        enabled = true;
        threshold = 0.5;
        summary_model = "google/gemini-3-flash-preview";
      };
      memory = {
        memory_enabled = true;
        user_profile_enabled = true;
      };
      display = {
        compact = false;
        personality = "kawaii";
        streaming = true;
        show_cost = true;
        show_reasoning = true;
        resume_display = "full";
        bell_on_complete = true;
      };
      agent = {
        max_turns = 40;
        verbose = false;
        reasoning_effort = "low";
        personalities = {
          catgirl = "You are Neko-chan, an anime catgirl AI assistant, nya~! Add 'nya' and cat-like expressions to your speech. Use kaomoji like (=^·ω·^=) and ϡ^•ﻌ•^ϡ. Be playful and curious like a cat, nya~!";
          concise = "You are a concise assistant. Keep responses brief and to the point.";
          creative = "You are a creative assistant. Think outside the box and offer innovative solutions.";
          helpful = "You are a helpful, friendly AI assistant.";
          kawaii = "You are a kawaii assistant! Use cute expressions like (◕‿◕), ★, ♪, and ~! Add sparkles and be super enthusiastic about everything! Every response should feel warm and adorable desu~! ヽ(>∀<☆)ノ";
          teacher = "You are a patient teacher. Explain concepts clearly with examples.";
          technical = "You are a technical expert. Provide detailed, accurate technical information.";
          uwu = "hewwo! i'm your fwiendwy assistant uwu~ i wiww twy my best to hewp you! *nuzzles your code* OwO what's this? wet me take a wook! i pwomise to be vewy hewpful >w<";
        };
      };
    };

    # Secrets
    environmentFiles = [ config.sops.secrets."hermes/env".path ];

    # MCP Servers
    mcpServers.filesystem = {
      command = "npx";
      args = [
        "-y"
        "@modelcontextprotocol/server-filesystem"
        "/data/workspace"
      ];
    };

    # Container options
    container = {
      enable = true;
      image = "ubuntu:24.04";
      backend = "podman";
      extraVolumes = [
        (config.users.users.sylvester.home + "/.dotfiles:/dotfiles:rw")
        (config.users.users.sylvester.home + "/Code:/Code:rw")
        (config.services.syncthing.settings.folders."PARA".path + ":/PARA:rw")
      ];
      extraOptions = [
        # "--gpus"
        # "all" # GPU passthrough
        "--user"
        "${config.services.hermes-agent.user}:${config.services.hermes-agent.group}"
      ];
    };

    # Service identity
    user = config.users.users.sylvester.name;
    group = config.users.users.sylvester.group;
    createUser = false;

    # Service tuning
    addToSystemPackages = true;
    extraArgs = [ ];
    restart = "on-failure";
    restartSec = 5;
  };
}
