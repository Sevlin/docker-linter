#!/usr/bin/env bash

#
# Execute command if specified
#
if [[ -n ${1} ]]; then
    # shellcheck disable=SC2068
    exec ${@}

#
# Fallback to specified linter
#
elif [[ -n ${PLUGIN_LINT} ]]; then
    case "${PLUGIN_LINT,,}" in
        shell|bash|sh)
            lint-shell
        ;;
        yml|yaml)
            lint-yaml
        ;;
        docker|dockerfile)
            lint-dockerfile
        ;;
        php)
            lint-php
        ;;
        *)
            echo "Unknown linter: ${PLUGIN_LINT}" 2>&1
            exit 1
        ;;
    esac

#
# Le WUT?
#
else
    echo "No linter nor command specified, exiting..." 2>&1
    exit 1
fi

