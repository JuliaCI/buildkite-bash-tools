#!/usr/bin/env bash

# Helper function to kill execution when something goes wrong
function die() {
    echo "ERROR: ${1}" >&2
    if which buildkite-agent >/dev/null 2>/dev/null; then
        # By default, the annotation context is unique to the message
        local CONTEXT=$(echo "${1}" | ${SHASUM})
        if [[ "$#" -gt 1 ]]; then
            CONTEXT="${2}"
        fi
        ERROR_MESSAGE="${1}"
        if [[ -v "PLUGIN_PREFIX" ]]; then
            ERROR_MESSAGE="${PLUGIN_PREFIX}: ${1}"
        fi
        buildkite-agent annotate --context="${CONTEXT}" --style=error "${ERROR_MESSAGE}"
    fi
    exit 1
}

# Read in one of buildkite's array variable types
function collect_buildkite_array() {
    PARAMETER_NAME="${1}"
    SUFFIX="${2:-}"
    if [[ -n "${SUFFIX}" ]] && [[ "${SUFFIX}" != _* ]]; then
        SUFFIX="_${SUFFIX}"
    fi

    local IDX=0
    while [[ -v "${PARAMETER_NAME}_${IDX}${SUFFIX}" ]]; do
        # Fetch the pattern
        VARNAME="${PARAMETER_NAME}_${IDX}${SUFFIX}"
        printf "%s\0" "${!VARNAME}"

        IDX=$((${IDX} + 1))
    done
}
