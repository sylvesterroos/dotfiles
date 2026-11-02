import pathlib
import sys

import yaml

MODELS = {
    "B02340820000": "MX Master 3",
    "B03400000000": "MX Master 3S",
}
GESTURE_BUTTON_CONTROL_ID = 195
MOUSE_GESTURES = 2

solaar_version = sys.argv[1]
path = pathlib.Path.home() / ".config/solaar/config.yaml"

config = yaml.safe_load(path.read_text()) if path.exists() else [solaar_version]
for model_id, name in MODELS.items():
    entry = next((e for e in config[1:] if e.get("_modelId") == model_id), None)
    if entry is None:
        entry = {"_NAME": name, "_modelId": model_id}
        config.append(entry)
    entry.setdefault("divert-keys", {})[GESTURE_BUTTON_CONTROL_ID] = MOUSE_GESTURES

path.parent.mkdir(parents=True, exist_ok=True)
path.write_text(yaml.safe_dump(config))
