#!/usr/bin/env bash
while read -r repo; do
  (
    cd repos/${repo/\//-}
    if [ -f mkdocs.yml ]; then
      echo $repo
    fi
  )
done < repos.txt
