#!/bin/bash
if [ "$(which plymouth-rpi-spinner)" != "" ]; then
  echo "Change plymouth theme to rpi-spinner ..."
  plymouth-rpi-spinner --activate >/dev/null 2>&1
fi
systemctl daemon-reload >/dev/null 2>&1
exit 0