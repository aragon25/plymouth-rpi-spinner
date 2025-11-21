#!/bin/bash
if [ "$(plymouth-set-default-theme)" == "rpi-spinner" ] && [ "$1" == "remove" ]; then
  echo "Change plymouth theme to details ..."
  plymouth-set-default-theme -R details >/dev/null 2>&1
fi
exit 0