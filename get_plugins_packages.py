import sys
from pathlib import Path

import yaml

yaml.SafeLoader.add_constructor("!ENV", lambda loader, node: None)
yaml.SafeLoader.add_multi_constructor("tag:yaml.org,2002:python/name:", lambda loader, suffix, node: None)
yaml.SafeLoader.add_multi_constructor("tag:yaml.org,2002:python/object/apply:", lambda loader, suffix, node: None)

def read_plugins(directory, plugin_map):
    mkdocs_data = yaml.load((Path(directory) / "mkdocs.yml").read_text(), Loader=yaml.SafeLoader)
    plugins = [p if isinstance(p, str) else list(p.keys())[0] for p in mkdocs_data.get("plugins", [])]
    try:
        plugins.remove("search")
    except ValueError:
        pass
    return [plugin_map.get(p, p) for p in plugins]


if __name__ == "__main__":
    plugin_map = yaml.safe_load(Path("plugin_map.yml").read_text())
    print("\n".join(read_plugins(sys.argv[1], plugin_map)))
