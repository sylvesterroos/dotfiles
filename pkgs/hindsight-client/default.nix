# Python client for the Hindsight memory API, as the Hermes hindsight plugin
# imports it. Its dependencies (aiohttp, pydantic, ...) come from the Hermes
# venv that loads it.
{ python312Packages }:
python312Packages.buildPythonPackage rec {
  pname = "hindsight_client";
  version = "0.10.2";
  format = "wheel";

  src = python312Packages.fetchPypi {
    inherit pname version format;
    dist = "py3";
    python = "py3";
    hash = "sha256-aEPmJdgTMzpCykv/OOjKs5tY7G7Voz1+tZb3HhbH72Q=";
  };

  dontCheckRuntimeDeps = true;
}
