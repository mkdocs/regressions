#!/usr/bin/env bash

set -e -u -o pipefail

if [[ "$1" =~ "/" ]]; then
    cmd="check"
else
    cmd="$1"
    shift
fi

repo="$1"
to_upgrade="${2:-git+https://github.com/mkdocs/mkdocs.git}"

project_dir="repos/${repo/\//--}"

group() {
    echo "::group::$1"
    shift
    "$@" && echo "::endgroup::"
}

setup() {
    if ! [[ -d "venv" ]]; then
        python -m venv venv
        venv/bin/pip install -U -r requirements.txt
    fi
}

clone_repo() {
    mkdir -p "$project_dir"
    if ! [[ -d "$project_dir/repo" ]]; then
        echo "Cloning" "https://github.com/$repo"
        git clone "https://github.com/$repo" "$project_dir/repo" --depth=1 --recursive &>/dev/null
    fi
    mkdocs_yml=$(cd "$project_dir/repo" && (2>/dev/null ls *mkdocs.y*ml || ls */mkdocs.y*ml) | head -1)
    if ! [[ -d "$project_dir/venv" ]]; then
        venv/bin/virtualenv "$project_dir/venv"
    fi
}

_build() {
    echo "==== Building $1 ===="
    "$project_dir/venv/bin/pip" freeze > "$project_dir/freeze-$1.txt"
    (set -x; cd "$project_dir/repo"; ../venv/bin/mkdocs build --no-strict -f "$mkdocs_yml" -d "$(pwd)/../site-$1")
    find "$project_dir/site-$1" -name "*.html" -print0 | xargs -0 -n16 -P4 venv/bin/python normalize_file.py
}

build_current() {
    clone_repo
    deps=($(venv/bin/mkdocs get-deps -f "$project_dir/repo/$mkdocs_yml" || true))
    group "Installing ${deps[*]}" \
    "$project_dir/venv/bin/pip" install -U --force-reinstall "${deps[@]}"
    (export PYTHONPATH=; _build current)
}

build_latest() {
    [ -n "$to_upgrade" ] || return
    clone_repo
    group "Upgrading $to_upgrade" \
    "$project_dir/venv/bin/pip" install -U --force-reinstall "$to_upgrade"
    _build latest
}

compare() {
    diff=$(diff -U0 "$project_dir/freeze-current.txt" "$project_dir/freeze-latest.txt") ||
        group "Diff of freezes" \
        echo "$diff"
    echo "==== Comparing ===="
    diff \
        -X exclude_patterns.txt \
        -B --suppress-blank-empty \
        --suppress-common-lines \
        -U2 -w -r "$project_dir/site-current" "$project_dir/site-latest"
}

check() {
    setup
    build_current
    build_latest
    compare
}

"$cmd"
