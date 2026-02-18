#!/bin/bash
if [ -f "/usr/lib/rpi-spinner/first_install" ]; then
  rm -f "/usr/lib/rpi-spinner/first_install" >/dev/null 2>&1
  echo "Change plymouth theme to rpi-spinner ..."
  plymouth-rpi-spinner --activate >/dev/null 2>&1
fi
systemctl daemon-reload >/dev/null 2>&1
exit 0