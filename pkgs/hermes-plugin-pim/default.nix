# Provider-independent information management tools for Hermes: mail, calendar and
# contacts, packaged so Hermes finds them through the `hermes_agent.plugins`
# entry point once the package is on PYTHONPATH.
{ pythonPackages }:
pythonPackages.buildPythonPackage {
  pname = "hermes-pim";
  version = "0.1.0";
  pyproject = true;

  src = ./.;

  build-system = [ pythonPackages.setuptools ];

  nativeCheckInputs = [ pythonPackages.pytestCheckHook ];
}
