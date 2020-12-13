import sys
from pathlib import Path

import yaml


def read_plugins(directory, plugin_map):
    mkdocs_data = yaml.load((Path(directory) / "mkdocs.yml").read_text(), Loader=yaml.Loader)
    plugins = [p if isinstance(p, str) else list(p.keys())[0] for p in mkdocs_data.get("plugins", [])]
    try:
        plugins.remove("search")
    except ValueError:
        pass
    return [plugin_map.get(p, p) for p in plugins]


if __name__ == "__main__":
    plugin_map = yaml.safe_load(Path("plugin_map.yml").read_text())
    print("\n".join(read_plugins(sys.argv[1], plugin_map)))
