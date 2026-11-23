# Python client for the Hindsight memory API used by the Hermes plugin.
{ nix-update-script, pythonPackages }:
pythonPackages.buildPythonPackage rec {
  pname = "hindsight_client";
  version = "1.2.3";
  pyproject = true;

  src = pythonPackages.fetchPypi {
    inherit pname version;
    hash = "sha256-J2N24Txefgbyv6SsXRD7g2dvYHLtFyrH0mE93rEQ9Gk=";
  };

  build-system = [ pythonPackages.hatchling ];

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

  passthru.updateScript = nix-update-script { extraArgs = [ "--flake" ]; };
}
