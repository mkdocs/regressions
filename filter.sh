#!/usr/bin/env bash
while read -r repo; do
  (
    cd repos/${repo/\//-}
    if [ -f setup.py -o -f pyproject.toml ] && [ -f mkdocs.yml ]; then
      echo $repo
    fi
  )
done < repos.txt
