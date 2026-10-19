# The Home Assistant gateway platform and ha_* tools for Hermes, packaged so
# Hermes finds it through the `hermes_agent.plugins` entry point once it is on
# PYTHONPATH.
{
  fetchFromGitHub,
  pythonPackages,
}:
pythonPackages.buildPythonPackage {
  pname = "hermes-plugin-homeassistant";
  version = "2.0.1-unstable-2026-10-19";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "NousResearch";
    repo = "hermes-official-plugins";
    rev = "c6f130d195298ace7d0e84bab8efdfa2bcdc57c8";
    hash = "sha256-CPXAtt1gWYjekkKeYfAxbmLMb3pyKfgD8EAgdLiP4yQ=";
  };
  sourceRoot = "source/homeassistant";

  # Upstream ships a directory plugin; move it into a package and declare the
  # entry point. Its one dependency, aiohttp, comes from the Hermes venv.
  postPatch = ''
    mkdir hermes_homeassistant
    mv *.py hermes_homeassistant/
    cat > pyproject.toml <<'EOF'
    [build-system]
    requires = ["setuptools"]
    build-backend = "setuptools.build_meta"

    [project]
    name = "hermes-plugin-homeassistant"
    version = "2.0.1"

    [project.entry-points."hermes_agent.plugins"]
    homeassistant = "hermes_homeassistant"

    [tool.setuptools]
    packages = ["hermes_homeassistant"]
    EOF
  '';

  build-system = [ pythonPackages.setuptools ];

  # Imports Hermes modules, which only the Hermes venv provides.
  dontCheckRuntimeDeps = true;
  dontUsePythonImportsCheck = true;
}
