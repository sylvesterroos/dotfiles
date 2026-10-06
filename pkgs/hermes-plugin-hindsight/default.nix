# The Hindsight memory provider for Hermes, packaged so Hermes finds it through
# the `hermes_agent.memory_providers` entry point once it is on PYTHONPATH.
{
  callPackage,
  fetchFromGitHub,
  python312Packages,
}:
python312Packages.buildPythonPackage {
  pname = "hermes-plugin-hindsight";
  version = "1.2.1";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "vectorize-io";
    repo = "hindsight";
    tag = "integrations/hermes/v1.2.1";
    hash = "sha256-L5HjVF64foSslizP6FPvEcnzorK4LY78YnuuP8rfEcA=";
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

  build-system = [ python312Packages.setuptools ];
  dependencies = [ (callPackage ../hindsight-client { }) ];

  # Imports Hermes modules, which only the Hermes venv provides.
  dontCheckRuntimeDeps = true;
  dontUsePythonImportsCheck = true;
}
