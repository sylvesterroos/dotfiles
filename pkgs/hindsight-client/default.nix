# Python client for the Hindsight memory API used by the Hermes plugin.
{ pythonPackages }:
pythonPackages.buildPythonPackage rec {
  pname = "hindsight_client";
  version = "0.10.2";
  format = "wheel";

  src = pythonPackages.fetchPypi {
    inherit pname version format;
    dist = "py3";
    python = "py3";
    hash = "sha256-aEPmJdgTMzpCykv/OOjKs5tY7G7Voz1+tZb3HhbH72Q=";
  };

  dependencies = with pythonPackages; [
    aiohttp-retry
    aiohttp
    pydantic
    python-dateutil
    typing-extensions
    urllib3
    yarl
  ];
  pythonImportsCheck = [ "hindsight_client" ];
}
