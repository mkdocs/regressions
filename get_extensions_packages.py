import sys
from pathlib import Path

import yaml

yaml.SafeLoader.add_constructor("!ENV", lambda loader, node: None)
yaml.SafeLoader.add_multi_constructor("tag:yaml.org,2002:python/name:", lambda loader, suffix, node: None)
yaml.SafeLoader.add_multi_constructor("tag:yaml.org,2002:python/object/apply:", lambda loader, suffix, node: None)

def read_extensions(directory, extension_map):
    mkdocs_data = yaml.load((Path(directory) / "mkdocs.yml").read_text(), Loader=yaml.SafeLoader)
    extensions = {e if isinstance(e, str) else list(e.keys())[0] for e in mkdocs_data.get("markdown_extensions", [])}
    extensions = {e.split(".", 1)[0] for e in extensions}
    native_exts = {
        "abbr",
        "admonition",
        "attr_list",
        "footnotes",
        "def_list",
        "meta",
        "codehilite",
        "extra",
        "markdown",
        "toc",
        "tables",
        "md_in_html",
        "fenced_code",
        "legacy_attrs",
        "legacy_em",
        "nl2br",
        "sane_lists",
        "smarty",
        "wikilinks",
    }
    extensions = extensions - native_exts
    return [extension_map.get(e, e) for e in extensions]


if __name__ == "__main__":
    extension_map = yaml.safe_load(Path("extension_map.yml").read_text())
    print("\n".join(read_extensions(sys.argv[1], extension_map)))
