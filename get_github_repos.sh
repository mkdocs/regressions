#!/usr/bin/env bash

set -o pipefail
page=1
while curl -s -H "Authorization: token $GITHUB_TOKEN" 'https://api.github.com/search/code?q=mkdocstrings+filename%3Amkdocs.yml&page='"$page" |
      jq -r '.items[].repository.url' |
      xargs -n1 curl -s -H "Authorization: token $GITHUB_TOKEN" |
      jq -r '"\(.stargazers_count) \(.html_url)"' ;
do
  ((page++))
done
