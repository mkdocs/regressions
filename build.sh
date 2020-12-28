#!/usr/bin/env bash

set +e
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
    # mkdocs-material must be installed before others
    # in case emoji_index: !!python/name:materialx.emoji... is used in mkdocs.yml
    grep -q material repos/$1/mkdocs.yml && repos/$1/venv/bin/python -m pip install mkdocs-material

    # plugins
    plugins=$(repos/$1/venv/bin/python get_plugins_packages.py repos/$1)
    
    # extensions
    extensions=$(repos/$1/venv/bin/python get_extensions_packages.py repos/$1)

    # install
    repos/$1/venv/bin/python -m pip install $plugins $extensions
}

install_self() {
    (cd repos/$1; venv/bin/python -m pip install .)
}

prettify_file() {
    if [ -d venv ]; then
        python=venv/bin/python
    else
        python=python
    fi
    prettified="$($python -c "import bs4, sys, pathlib; print(bs4.BeautifulSoup(pathlib.Path('$1').read_text()).prettify())")"
    echo "${prettified}" > "$1"
}

prettify_dir() {
    find repos/$1/$2 -name "*.html" | while read -r html_file; do
        prettify_file "${html_file}"
    done
}

pip_freeze_current() {
    repos/$1/venv/bin/python -m pip freeze > freeze-$1-current.txt
}

pip_freeze_latest() {
    repos/$1/venv/bin/python -m pip freeze > freeze-$1-latest.txt
}

freeze_diff() {
    diff -U0 freeze-$1-current.txt freeze-$1-latest.txt
}

build_current() {
    (cd repos/$1; venv/bin/mkdocs build -v -d site_current)
}

upgrade_mkdocstrings() {
    repos/$1/venv/bin/python -m pip uninstall -y mkdocstrings
    [ ! -e ./mkdocstrings ] && git clone https://github.com/pawamoy/mkdocstrings --depth=1
    repos/$1/venv/bin/python -m pip install ./mkdocstrings
}

build_latest() {
    (cd repos/$1; venv/bin/mkdocs build -v -d site_latest)
}

do_diff() {
    diff_output="$(
        diff \
            -X exclude_patterns.txt \
            -B --suppress-blank-empty \
            --suppress-common-lines \
            -U0 -w -r repos/$1/site_current repos/$1/site_latest
    )"
    echo "${diff_output}"
    if [ -n "$(grep -Ev \
                -e '^[^+-]' \
                -e '^(\+\+\+|---)' \
                -e '^\+\s+</(span|code)>' \
                -e '^\+\s+<span class="(n|o|fm|nb)">' \
                -e '^\+\s+<code class="highlight language-python">' \
                -e '^[+-]Build Date UTC :' \
                -e '[a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12}' \
                -e '0x[a-f0-9]+' <<<"${diff_output}")" ]; then
        return 1
    fi
    return 0
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
    if [ $RESUME_AT_LATEST -eq 0 ]; then
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
        msg "freezing current"
        pip_freeze_current $d
        msg "building current"
        ! build_current $d && return 1
        msg "prettifying"
        prettify_dir $d site_current
        [ $STOP_AT_CURRENT -eq 1 ] && return 0
    else
        d=${1/\//-}
    fi
    msg "upgrading mkdocstrings"
    upgrade_mkdocstrings $d
    msg "freezing latest"
    pip_freeze_latest $d
    msg "diffing freezes"
    freeze_diff $d
    msg "building latest"
    ! build_latest $d && return 2
    msg "prettifying"
    prettify_dir $d site_latest
    msg "diffing"
    ! do_diff $d | tee diff-$d.diff && return 2
    rm diff-$d.diff
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
    cat repos.txt | parallel bash build.sh one_silent {}
}

main() {
    STOP_AT_CURRENT=0
    RESUME_AT_LATEST=0
    case $1 in
        one) do_one $2 ;;
        one_current) STOP_AT_CURRENT=1; do_one $2 ;;
        one_latest) RESUME_AT_LATEST=1; do_one $2 ;;
        one_silent) do_one_silent $2 ;;
        all) do_all ;;
    esac
}

main "$@"
