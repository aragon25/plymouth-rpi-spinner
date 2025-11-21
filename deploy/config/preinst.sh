#!/bin/bash
if [ "$(which plymouth-rpi-spinner)" != "" ] && [ "$1" == "install" ]; then
  echo "The command \"plymouth-rpi-spinner\" is already present. Can not install this."
  echo "File: \"$(which plymouth-rpi-spinner)\""
  exit 1
fi
if [ -f "/usr/share/plymouth/themes/rpi-spinner/rpi-spinner.plymouth" ] && [ "$1" == "install" ]; then
  echo "The theme \"rpi-spinner\" is already present. Can not install this."
  echo "File: \"/usr/share/plymouth/themes/rpi-spinner/rpi-spinner.plymouth\""
  exit 1
fi
exit 0