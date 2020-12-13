import sys
from pathlib import Path

import yaml


def read_plugins(directory):
    mkdocs_data = yaml.load((Path(directory) / "mkdocs.yml").read_text(), Loader=yaml.Loader)
    plugins = [p if isinstance(p, str) else list(p.keys())[0] for p in mkdocs_data.get("plugins", [])]
    try:
        plugins.remove("search")
    except ValueError:
        pass
    return plugins


if __name__ == "__main__":
    for d in sys.argv[1:]:
        print("\n".join(read_plugins(d)))
