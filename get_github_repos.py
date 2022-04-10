import os
import time
from pathlib import Path

from github import Github

TOKEN = os.environ.get("GITHUB_TOKEN")
exclude = {line.split(" ", 1)[0] for line in Path("exclude_repos.txt").read_text().splitlines()}


def get_repos():
    github = Github(TOKEN)
    search = github.search_code("mkdocstrings filename:mkdocs.yml path:/")
    repos = []
    for result in search:
        repo = result.repository
        print(repo.full_name, repo.stargazers_count)
        repos.append(repo)
        time.sleep(2)
    repos = sorted(repos, key=lambda repo: repo.stargazers_count, reverse=True)
    return [repo.full_name for repo in repos if repo.full_name not in exclude]


if __name__ == "__main__":
    print("\n".join(get_repos()))
