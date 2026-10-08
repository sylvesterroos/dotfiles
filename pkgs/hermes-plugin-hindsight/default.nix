# The Hindsight memory provider for Hermes, packaged so Hermes finds it through
# the `hermes_agent.memory_providers` entry point once it is on PYTHONPATH.
{
  callPackage,
  fetchFromGitHub,
  pythonPackages,
}:
pythonPackages.buildPythonPackage {
  pname = "hermes-plugin-hindsight";
  version = "1.2.1-unstable-2026-10-07";
  pyproject = true;

  # Includes ordinary memory-write mirroring and recall relevance filtering.
  src = fetchFromGitHub {
    owner = "vectorize-io";
    repo = "hindsight";
    rev = "ea5ab3034ceb1fed601950ec8996c69363c0b0b6";
    hash = "sha256-STVPvTfuVbkvMssaVeSLg1h6XBbGNXts5jlXb4V8RVI=";
  };
  sourceRoot = "source/hindsight-integrations/hermes";

  # Upstream ships a directory plugin; move it into a package and declare the
  # entry point. hindsight-embed only serves the embedded mode, so the client
  # is the one dependency.
  postPatch = ''
    mkdir hermes_hindsight
    mv *.py plugin.yaml hermes_hindsight/
    cat > pyproject.toml <<'EOF'
    [build-system]
    requires = ["setuptools"]
    build-backend = "setuptools.build_meta"

    [project]
    name = "hermes-plugin-hindsight"
    version = "1.2.1"
    dependencies = ["hindsight-client"]

    [project.entry-points."hermes_agent.memory_providers"]
    hindsight = "hermes_hindsight"

    [tool.setuptools]
    packages = ["hermes_hindsight"]
    package-data = { hermes_hindsight = ["plugin.yaml"] }
    EOF
  '';

  build-system = [ pythonPackages.setuptools ];
  dependencies = [ (callPackage ../hindsight-client { inherit pythonPackages; }) ];

  # Imports Hermes modules, which only the Hermes venv provides.
  dontCheckRuntimeDeps = true;
  dontUsePythonImportsCheck = true;
}
