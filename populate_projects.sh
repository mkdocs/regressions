#!/usr/bin/env bash

set -e -u -o pipefail

cd projects

github_auth=()
if [[ -n "${GITHUB_TOKEN:-}" ]]; then
  github_auth=(--header "Authorization: Bearer $GITHUB_TOKEN")
fi

for d in */; do
  d="${d%/}"
  pushd "$d"
  printf "%s -> " "$d" >&2
  if [[ -f 'project.txt' ]]; then
    [[ "$(head -1 'project.txt')" =~ ^https://github.com/([^/]+/[^/]+)/blob/([^/]+)/(.+)$ ]]
    repo="${BASH_REMATCH[1]}"
    branch="${BASH_REMATCH[2]}"
    mkdocs_yml="${BASH_REMATCH[3]}"
  else
    repo="${d//--//}"
    branch=$(curl -sfL "${github_auth[@]}" "https://api.github.com/repos/$repo" | jq -r '.default_branch')
    mkdocs_yml='mkdocs.yml'
  fi
  [[ "$(curl -sfL "${github_auth[@]}" "https://api.github.com/repos/$repo/commits?per_page=1&sha=$branch" | jq -r '.[0].commit.url')" =~ ^https://api.github.com/repos/([^/]+/[^/]+)/git/commits/([0-9a-f]+)$ ]]
  repo="${BASH_REMATCH[1]}"
  commit="${BASH_REMATCH[2]}"
  echo "https://github.com/$repo/blob/$branch/$mkdocs_yml" | tee /dev/stderr >project.txt
  echo "https://github.com/$repo/raw/$commit/$mkdocs_yml" >>project.txt
  tail -1 project.txt | xargs curl -sfL | (mkdocs-get-deps -f - || true) | grep . >requirements.in.new
  (grep -qE ' ' requirements.in || true) >>requirements.in.new
  mv requirements.in.new requirements.in
  popd
  # Rename the directory in case the repository has been renamed
  dir_name="${repo//\//--}"
  if [[ "$d" != "$dir_name" ]]; then
    mv "$d" "$dir_name"
  fi
done

echo */requirements.in | xargs -t -n1 -P4 pip-compile -q --allow-unsafe --strip-extras --no-annotate --no-header -U
