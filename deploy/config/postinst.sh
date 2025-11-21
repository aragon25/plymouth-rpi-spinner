#!/bin/bash
if [ "$(plymouth-set-default-theme)" != "rpi-spinner" ]; then
  echo "Change plymouth theme to rpi-spinner ..."
  plymouth-set-default-theme -R rpi-spinner >/dev/null 2>&1
fi
systemctl daemon-reload >/dev/null 2>&1
exit 0