# The librarian tools for Hermes: ref-aware reads of cached remote git
# repositories, packaged so Hermes finds them through the
# `hermes_agent.plugins` entry point once the package is on PYTHONPATH.
{
  git,
  pythonPackages,
}:
pythonPackages.buildPythonPackage {
  pname = "hermes-librarian";
  version = "0.1.0";
  pyproject = true;

  src = ./.;

  build-system = [ pythonPackages.setuptools ];

  nativeCheckInputs = [
    git
    pythonPackages.pytestCheckHook
  ];
}
