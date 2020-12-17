#!/usr/bin/env bash

RET=0

CUR_DIR=$(pwd)
DOCKER_FILES=$(find "${CUR_DIR}" -type f -iname 'Dockerfile*')

for DKR_F in ${DOCKER_FILES[*]}; do
    hadolint "${DKR_F}" \
    || RET=${?}
done

exit ${RET}

