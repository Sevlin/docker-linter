#!/usr/bin/env bash

# MIT License Copyright (c) 2021, Ukraine, Kyiv, Mykyta Solomko <sev@nix.org.ua>
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is furnished
# to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice (including the next
# paragraph) shall be included in all copies or substantial portions of the
# Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
# FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS
# OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
# WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF
# OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

#
# Use PWD as Home for Drone/Woodpecker CI
# to be able to search for dotfiles as configs
#
if [[ ${CI_SYSTEM} = drone ]]; then
    HOME="$(pwd)"
    export HOME
fi

#
# Exit on first pipe failure
#
set -o pipefail

#
# Enable debug
#
if [[ -n ${PLUGIN_DEBUG} ]]; then
    set -o xtrace
fi

#
# Exit on errors
#
if [[ -n ${PLUGIN_ERREXIT} ]]; then
    set -o errexit
fi

#
# Some of linters doesn't scan directories, hence
# we need to provide them list of files to check
#
DIRS_TO_FILES=${DIRS_TO_FILES:-no}

DEF_IFS="${IFS}"
export IFS=','

RET=0
# shellcheck disable=SC2034
EXTRA_ARGS=''

_SEARCH_DIRS=${_SEARCH_DIRS:-/tmp/lint-dirs.txt}
_DIRS_UNSORTED=${_DIRS_UNSORTED:-/tmp/lint-dirs-unsorted.txt}
_CHECK_FILES=${_CHECK_FILES:-/tmp/lint-files.txt}
_FILES_UNSORTED=${_FILES_UNSORTED:-/tmp/lint-files-unsorted.txt}
_BEFORE_SCRIPT=${_BEFORE_SCRIPT:-/tmp/lint-before.sh}

touch "${_SEARCH_DIRS}" \
      "${_CHECK_FILES}" \
      "${_DIRS_UNSORTED}" \
      "${_FILES_UNSORTED}"

before_script()
{
    if [[ -n ${PLUGIN_BEFORE_SCRIPT} ]]; then

        #
        # Add script's body defore commands
        #
        cat > "${_BEFORE_SCRIPT}" << EOF
#!/usr/bin/env bash
set -o errexit
set -o pipefail
set -o xtrace

EOF
        # shellcheck disable=SC2068
        for _cmd in ${PLUGIN_BEFORE_SCRIPT[@]}; do
            echo "${_cmd}" >> "${_BEFORE_SCRIPT}"
        done

        #
        # Show before-script content
        #
        if [[ -n ${PLUGIN_DEBUG} ]]; then
            echo "=== BEFORE SCRIPT (content) ==="
            cat "${_BEFORE_SCRIPT}"
            echo "==============================="
            echo
        fi

        echo "=== BEFORE SCRIPT ==="
        echo
        IFS="${DEF_IFS}" bash "${_BEFORE_SCRIPT}" || exit 1
        echo
        echo "====================="
        echo
    fi
}

_dir_list()
{
    #
    # Check directories
    #
    for _d in ${PLUGIN_PATH[*]}; do
        if [[ -d ${_d} ]]; then
            readlink -f "${_d}" >> "${_DIRS_UNSORTED}"
        else
            echo ">>> Directory ${_d} does not exist!" 1>&2
            RET=1
        fi
    done

    #
    # Exit on failed dirs
    #
    if [[ ${RET} -ne 0 ]]; then
        exit ${RET}
    fi

    # shellcheck disable=SC2002
    cat "${_DIRS_UNSORTED}" \
    | sort -n \
    | uniq \
    > "${_SEARCH_DIRS}"
}

_find_shell()
{
    while read -r _d; do
        find "${_d}" -type f -name '*.sh' \
            >> "${_FILES_UNSORTED}"
    done < "${_SEARCH_DIRS}"
}

_find_yaml()
{
    while read -r _d; do
        find "${_d}" -type f \( -iname '*.yml' -or -iname '*.yaml' \) \
            >> "${_FILES_UNSORTED}"
    done < "${_SEARCH_DIRS}"
}

_find_docker()
{
    while read -r _d; do
        find "${_d}" -type f -name 'Dockerfile*' \
            >> "${_FILES_UNSORTED}"
    done < "${_SEARCH_DIRS}"
}

_find_php()
{
    while read -r _d; do
        find "${_d}" -type f -name '*.php' \
            >> "${_FILES_UNSORTED}"
    done < "${_SEARCH_DIRS}"
}


_file_list()
{
    #
    # Build file list
    #
    for _f in ${PLUGIN_FILES[*]}; do
        if [[ -f ${_f} ]]; then
            readlink -f "${_f}" >> "${_FILES_UNSORTED}"
        else
            echo ">>> File ${_f} can't be checked!" 1>&2
        fi
    done

    #
    # Search dirs for files (DIRS_TO_FILES)
    #
    [[ ${DIRS_TO_FILES} == yes ]] \
    && case "${PLUGIN_LINT,,}" in
           shell|bash|sh)
               _find_shell
           ;;
           yml|yaml)
               _find_yaml
           ;;
           docker|dockerfile)
               _find_docker
           ;;
           php)
               _find_php
           ;;
           *)
               :
           ;;
       esac

    #
    # Remove duplicates and count files
    #
    # shellcheck disable=SC2002
    cat "${_FILES_UNSORTED}" \
    | sort -n \
    | uniq \
    > "${_CHECK_FILES}"
}

build_file_list()
{
    if [[ -z ${PLUGIN_PATH} ]] \
    && [[ -z ${PLUGIN_FILES} ]]; then
        PLUGIN_PATH="$(pwd)"
        export PLUGIN_PATH
    fi

    _dir_list
    _file_list
}

