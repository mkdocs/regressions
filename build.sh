#!/usr/bin/env bash

set -o pipefail
mkdir -p logs
mkdir -p repos

clone() {
    d=${1/\//-}
    if [ -d $d ]; then
        (cd $d; git pull)
    else
        git clone https://github.com/$1 repos/$d --depth=1 &>/dev/null
    fi
    echo $d
}

make_venv() {
    python -m venv repos/$1/venv
}

install_mkdocs() {
    repos/$1/venv/bin/python -m pip install mkdocs
}

install_deps() {
    plugins=$(python get_plugins_packages.py repos/$1)
    material=$(grep -q material repos/$1/mkdocs.yml && echo mkdocs-material)
    mkdocs_click=$(grep -q mkdocs-click repos/$1/mkdocs.yml && echo mkdocs-click)
    markdown_include=$(grep -q markdown_include.include repos/$1/mkdocs.yml && echo markdown-include)
    repos/$1/venv/bin/python -m pip install $plugins $material $mkdocs_click $markdown_include
}

install_self() {
    (cd repos/$1; venv/bin/python -m pip install .)
}

build_current() {
    (cd repos/$1; venv/bin/mkdocs build -d site_current)
}

upgrade_mkdocstrings() {
    repos/$1/venv/bin/python -m pip uninstall -y mkdocstrings
    repos/$1/venv/bin/python -m pip install ./mkdocstrings
}

build_latest() {
    (cd repos/$1; venv/bin/mkdocs build -d site_latest)
}

msg() {
    echo
    echo
    echo -e "====================================="
    echo -e "     $1"
    echo -e "====================================="
    echo
    echo
}

do_one() {
    msg "cloning"
    d=$(clone $1)
    msg "making venv"
    make_venv $d
    msg "installing mkdocs"
    install_mkdocs $d
    msg "installing deps"
    install_deps $d
    msg "installing self"
    install_self $d
    msg "building current"
    ! build_current $d && return 1
    msg "building latest"
    upgrade_mkdocstrings $d
    ! build_latest $d && return 2
    return 0
}

do_one_silent() {
    do_one $1 &>logs/build-${1/\//-}.log
    case $? in
        0) echo "$1: success" ;;
        1) echo "$1: skipped (build current failed)" ;;
        2) echo "$1: failed" ;;
    esac | tee -a results.log
}

do_all() {
    cat repos.txt | parallel --bar bash build.sh one_silent {}
}

main() {
    case $1 in
        one) do_one $2 ;;
        one_silent) do_one_silent $2 ;;
        all) do_all ;;
    esac
}

main "$@"
