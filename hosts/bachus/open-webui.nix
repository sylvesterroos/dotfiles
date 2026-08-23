{
  config,
  mv,
  ...
}:
{
  services.open-webui = {
    enable = true;
    package = mv.tip.open-webui;
    port = 3000;
    host = "127.0.0.1";
    openFirewall = false;
    environment = {
      # Skip chunking + embedding on upload; file text goes straight to the agent as context.
      BYPASS_EMBEDDING_AND_RETRIEVAL = "True";
    };
  };

  services.caddy.virtualHosts."chat.sylvesterroos.com".extraConfig = ''
    reverse_proxy 127.0.0.1:${toString config.services.open-webui.port}
  '';
}
