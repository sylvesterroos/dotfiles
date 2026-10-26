# The Hindsight memory provider for Hermes, packaged so Hermes finds it through
# the `hermes_agent.memory_providers` entry point once it is on PYTHONPATH.
{
  callPackage,
  fetchFromGitHub,
  nix-update-script,
  pythonPackages,
}:
pythonPackages.buildPythonPackage rec {
  pname = "hermes-plugin-hindsight";
  version = "1.2.3";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "vectorize-io";
    repo = "hindsight";
    tag = "integrations/hermes/v${version}";
    hash = "sha256-qEjN1JRGLH7iGDkCEEeIG5ciFRpggvMbjjmrQP+ThCo=";
  };
  sourceRoot = "source/hindsight-integrations/hermes";

  # Upstream ships a directory plugin whose pyproject.toml carries the project
  # metadata and dependency bounds. Move the plugin into a package and extend
  # that file with the build backend and the entry point.
  postPatch = ''
    mkdir hermes_hindsight
    mv *.py plugin.yaml hermes_hindsight/
    cat >> pyproject.toml <<'EOF'

    [build-system]
    requires = ["setuptools"]
    build-backend = "setuptools.build_meta"

    [project.entry-points."hermes_agent.memory_providers"]
    hindsight = "hermes_hindsight"

    [tool.setuptools]
    packages = ["hermes_hindsight"]
    package-data = { hermes_hindsight = ["plugin.yaml"] }
    EOF
  '';

  build-system = [ pythonPackages.setuptools ];
  dependencies = [ (callPackage ../hindsight-client { inherit pythonPackages; }) ];
  # hindsight-embed serves only the embedded mode; this setup talks to a server.
  pythonRemoveDeps = [ "hindsight-embed" ];

  # Imports Hermes modules, which only the Hermes venv provides.
  dontUsePythonImportsCheck = true;

  passthru.updateScript = nix-update-script {
    extraArgs = [
      "--flake"
      "--version-regex=integrations/hermes/v(.*)"
    ];
  };
}
