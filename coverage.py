import collections
import csv
import os
from pathlib import Path

usages = collections.defaultdict(list)
for f in sorted(Path(__file__).parent.glob("projects/*/requirements.in")):
    for requirement in f.read_text().splitlines():
        if not requirement or " " in requirement:
            continue
        usages[requirement].append(f.parent.name.replace("--", "/"))

history_projects = (
    Path(__file__).parent.joinpath("..", "mkdocs-catalog").glob("history/*_projects.csv")
)
with open(sorted(history_projects)[-1]) as f:
    for p in csv.DictReader(f):
        if p["pypi_id"] or p["github_id"]:
            install_id = p["pypi_id"] or "git+https://github.com/{github_id}".format_map(p)
            lines = []
            if themes := p["mkdocs_theme"]:
                lines.append(f"theme: {themes}")
            if plugins := p["mkdocs_plugin"]:
                lines.append(f"plugins: {plugins}")
            if extensions := p["markdown_extension"]:
                lines.append(f"markdown_extensions: {extensions}")
            if lines:
                if os.environ.get("GITHUB_ACTIONS"):
                    print("::group::", end="")
                print(f"{len(usages[install_id]):3}  {install_id}")
                for line in lines:
                    print(f"          {line}")
                if os.environ.get("GITHUB_ACTIONS"):
                    if usages[install_id]:
                        print(f"          Used by {', '.join(usages[install_id])}")
                    print("::endgroup::")
