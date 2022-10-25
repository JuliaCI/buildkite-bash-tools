#!/usr/bin/env bash
shopt -s extglob
shopt -s globstar

function collect_glob_pattern() {
    # First argument is either a glob pattern, or a directory.  If it is a directory,
    # we add `/**/*` to it in order to select everything underneath it.
    local target="${1}"
    local prefix="${1}"
    if [[ -d "${target}" ]]; then
        target="${target}/**/*"
    fi

    # Iterate over the glob pattern
    for f in ${target}; do
        # Ignore directories, only list files
        if [[ -f ${f} ]]; then
            printf "%s\0" "${f}"
        fi
    done
}
