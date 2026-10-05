{ ... }:
let
  host = "bachus";

  port = 18732;
in
{
  listen = "[::]:${toString port}";
  inherit host port;
  endpoint = "http://${host}:${toString port}/";
  cacheUrl = "http://${host}:${toString port}/bachus";
}
