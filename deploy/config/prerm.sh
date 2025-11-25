#!/bin/bash
if [ "$(which plymouth-rpi-spinner)" != "" ] && [ "$1" == "remove" ]; then
  echo "Change plymouth theme to default ..."
  plymouth-rpi-spinner --deactivate >/dev/null 2>&1
fi
exit 0