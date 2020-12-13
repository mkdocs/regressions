import sys
from pathlib import Path

import yaml


def read_extensions(directory):
    mkdocs_data = yaml.load((Path(directory) / "mkdocs.yml").read_text(), Loader=yaml.Loader)
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
    return extensions - native_exts


if __name__ == "__main__":
    for d in sys.argv[1:]:
        print("\n".join(read_extensions(d)))
