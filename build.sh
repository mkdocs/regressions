#!/usr/bin/env bash

set -e -u -o pipefail

if [[ "$1" =~ "/" ]]; then
    cmd="check"
else
    cmd="$1"
    shift
fi

repo_name="$1"
to_upgrade="${2:-git+https://github.com/mkdocs/mkdocs.git}"

info_dir="projects/${repo_name/\//--}"
repo_dir="repos/${repo_name/\//--}"

[[ "$(head -1 "$info_dir/project.txt")" =~ ^https://github.com/([^/]+/[^/]+)/blob/([^/]+)/(.+)$ ]]
repo="${BASH_REMATCH[1]}"
commit="${BASH_REMATCH[2]}"
mkdocs_yml="${BASH_REMATCH[3]}"


group() {
    echo "::group::$1"
    shift
    "$@" && echo "::endgroup::"
}

setup() {
    if ! [[ -d "venv" ]]; then
        python -m venv venv
        venv/bin/pip install -U beautifulsoup4 virtualenv
    fi
}

clone_repo() {
    mkdir -p "$repo_dir/repo"
    (
        export GIT_LFS_SKIP_SMUDGE=1
        cd "$repo_dir/repo"
        git init -b checkout
        git fetch --depth=1 "https://github.com/$repo" "$commit"
        git reset --hard FETCH_HEAD
    )
    if ! [[ -d "$repo_dir/venv" ]]; then
        venv/bin/virtualenv "$repo_dir/venv"
    fi
}

_build() {
    echo "==== Building $1 ===="
    "$repo_dir/venv/bin/pip" freeze > "$repo_dir/freeze-$1.txt"
    (
        if grep -q mkdocstrings "$info_dir/requirements.txt"; then
            export PYTHONPATH="src:.:${PYTHONPATH:+:${PYTHONPATH}}"
        fi
        if grep -q encryptcontent "$info_dir/requirements.txt"; then
            export MKDOCS_ENCRYPTCONTENT_INSECURE_TEST=true
        fi
        cd "$repo_dir/repo"
        ../venv/bin/mkdocs build --no-strict -f "$mkdocs_yml" -d "$(pwd)/../site-$1"
    )
    find "$repo_dir/site-$1" -name "*.html" -print0 | xargs -0 -n16 -P4 venv/bin/python normalize_file.py
}

build_current() {
    clone_repo
    group "Installing deps" \
    "$repo_dir/venv/bin/pip" install -U --force-reinstall --no-deps -r "$info_dir/requirements.txt"
    (export PYTHONPATH=; _build current)
}

build_latest() {
    [ -n "$to_upgrade" ] || return
    clone_repo
    group "Upgrading $to_upgrade" \
    "$repo_dir/venv/bin/pip" install -U --force-reinstall "$to_upgrade"
    _build latest
}

compare() {
    diff=$(diff -U0 "$repo_dir/freeze-current.txt" "$repo_dir/freeze-latest.txt") ||
        group "Diff of freezes" \
        echo "$diff"
    echo "==== Comparing ===="
    diff \
        -X exclude_patterns.txt \
        -B --suppress-blank-empty \
        --suppress-common-lines \
        -U2 -w -r "$repo_dir/site-current" "$repo_dir/site-latest"
}

check() {
    setup
    build_current
    build_latest
    compare
}

"$cmd"
