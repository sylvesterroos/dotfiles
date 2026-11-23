# The Home Assistant gateway platform and ha_* tools for Hermes, packaged so
# Hermes finds it through the `hermes_agent.plugins` entry point once it is on
# PYTHONPATH.
{
  fetchFromGitHub,
  nix-update-script,
  pythonPackages,
}:
pythonPackages.buildPythonPackage {
  # The project name upstream's pyproject.toml declares.
  pname = "hermes-homeassistant";
  version = "0-unstable-2026-11-20";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "NousResearch";
    repo = "hermes-official-plugins";
    rev = "269ddcbc8598ece2dc5bb82115ac68954bc4024f";
    hash = "sha256-/P7F8OvEjnU6/Uvq00LKkjYIoFMghpEF5alkYrdMpA8=";
  };
  sourceRoot = "source/homeassistant";

  # Upstream ships a directory plugin whose pyproject.toml carries the project
  # metadata and dependency bounds. Move the plugin into a package and extend
  # that file with the build backend and the entry point.
  postPatch = ''
    mkdir hermes_homeassistant
    mv *.py hermes_homeassistant/
    cat >> pyproject.toml <<'EOF'

    [build-system]
    requires = ["setuptools"]
    build-backend = "setuptools.build_meta"

    [project.entry-points."hermes_agent.plugins"]
    homeassistant = "hermes_homeassistant"

    [tool.setuptools]
    packages = ["hermes_homeassistant"]
    EOF
  '';

  build-system = [ pythonPackages.setuptools ];
  dependencies = [ pythonPackages.aiohttp ];

  # Imports Hermes modules, which only the Hermes venv provides.
  dontUsePythonImportsCheck = true;

  passthru.updateScript = nix-update-script {
    extraArgs = [
      "--flake"
      "--version=branch"
    ];
  };
}
