#!/usr/bin/env bash

set -e -u -o pipefail

cd projects

for d in */; do (
  d="${d%/}"
  cd "$d"
  printf "%s -> " "$d" >&2
  if [[ ! -f 'url.txt' ]]; then
    repo="https://github.com/${d//--//}"
    branch="$(git remote show "$repo" | grep -oP 'HEAD branch: \K.+')"
    echo "$repo/raw/$branch/mkdocs.yml" >url.txt
  fi
  cat url.txt >&2
  curl -sfL -- $(cat url.txt) | (mkdocs get-deps -f - || true) | grep . >requirements.in.new
  (grep -qE '[^a-zA-Z\-_]' requirements.in || true) >>requirements.in.new
  mv requirements.in.new requirements.in
); done

echo */requirements.in | xargs -t -n1 -P4 pip-compile -q --no-annotate --no-header -U
