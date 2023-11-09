#!/usr/bin/env bash

set -e -u -o pipefail

cd projects

for d in */; do (
  d="${d%/}"
  cd "$d"
  printf "%s -> " "$d" >&2
  if [[ -f 'project.txt' ]]; then
    [[ "$(head -1 'project.txt')" =~ ^https://github.com/([^/]+/[^/]+)/blob/([^/]+)/(.+)$ ]]
    repo="${BASH_REMATCH[1]}"
    branch="${BASH_REMATCH[2]}"
    mkdocs_yml="${BASH_REMATCH[3]}"
  else
    repo="${d//--//}"
    branch=''
    mkdocs_yml='mkdocs.yml'
  fi
  commit=$(curl -sfL "https://api.github.com/repos/$repo/commits?per_page=1&sha=$branch" | jq -r '.[0].sha')
  echo "https://github.com/$repo/blob/$branch/$mkdocs_yml" | tee /dev/stderr >project.txt
  echo "https://github.com/$repo/raw/$commit/$mkdocs_yml" >>project.txt
  tail -1 project.txt | xargs curl -sfL | (mkdocs get-deps -f - || true) | grep . >requirements.in.new
  (grep -qE ' ' requirements.in || true) >>requirements.in.new
  mv requirements.in.new requirements.in
); done

echo */requirements.in | xargs -t -n1 -P4 pip-compile -q --no-annotate --no-header -U
