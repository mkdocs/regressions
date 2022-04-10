#!/usr/bin/env bash

set -o pipefail
page=1
while curl -s -H "Authorization: token $GITHUB_TOKEN" 'https://api.github.com/search/code?q=mkdocstrings+filename%3Amkdocs.yml+path%3A/&page='"$page" |
  jq -r '.items[].repository.url' |
  xargs -n1 curl -s -H "Authorization: token $GITHUB_TOKEN" |
  jq -r '"\(.full_name)"' |
  while read -r repo; do
    if ! grep -Eq "\b${repo}\b" exclude_repos.txt; then
      if [ ! -d repos/${repo/\//-} ]; then
        git clone --depth=1 https://github.com/$repo repos/${repo/\//-}
      else
        (cd repos/${repo/\//-}; git pull)
      fi
      if [ -f repos/${repo/\//-}/mkdocs.yml ]; then
        echo $repo >> repos.txt
      else
        echo "$repo  # no mkdocs.yml" >> exclude_repos.txt
        rm -rf repos/${repo/\//-}
      fi
    fi
  done; do
  ((page++))
done
sort -u repos.txt -o repos.txt
sort -u exclude_repos.txt -o exclude_repos.txt
