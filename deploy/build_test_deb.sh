#!/bin/bash

SCRIPT_PATH="$(readlink -f "$0")"
SCRIPT_NAME="$(basename "$SCRIPT_PATH")"
SCRIPT_DIR="$(dirname "$SCRIPT_PATH")"

cd "${SCRIPT_DIR}"
chmod +x ${SCRIPT_DIR}/builder/build_deb.sh
${SCRIPT_DIR}/builder/build_deb.sh -t ${SCRIPT_DIR}/config/build_deb.conf