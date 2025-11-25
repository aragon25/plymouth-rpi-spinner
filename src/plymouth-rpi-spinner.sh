#!/bin/bash
##############################################
##                                          ##
##  plymouth-rpi-spinner                    ##
##                                          ##
##############################################

#get some variables
SCRIPT_TITLE="plymouth-rpi-spinner"
SCRIPT_VERSION="1.2"
SCRIPT_PATH="$(readlink -f "$0")"
SCRIPT_NAME="$(basename "$SCRIPT_PATH")"
SCRIPT_DIR="$(dirname "$SCRIPT_PATH")"

#!!!RUN RESTRICTIONS!!!
#only for raspberry pi (rpi5|rpi4|rpi3|all) can combined!
raspi=""
#only for Raspbian OS (trixie|bookworm|bullseye|all) can combined!
rasos=""
#only for cpu architecture (i386|armhf|amd64|arm64) can combined!
cpuarch=""
#only for os architecture (32|64) can NOT combined!
bsarch=""
#this aptpaks need to be installed!
aptpaks=( plymouth plymouth-themes )

#check commands
for i in "$@"
do
  case $i in
    -a|--activate)
    [ "$CMD" == "" ] && CMD="activate" || CMD="help"
    shift # past argument
    ;;
    -d|--deactivate)
    [ "$CMD" == "" ] && CMD="deactivate" || CMD="help"
    shift # past argument
    ;;
    -v|--version)
    [ "$CMD" == "" ] && CMD="version" || CMD="help"
    shift # past argument
    ;;
    -h|--help)
    CMD="help"
    shift # past argument
    ;;
    *)
    if [ "$i" != "" ]
    then
      echo "Unknown option: $i"
      exit 1
    fi
    ;;
  esac
done
[ "$CMD" == "" ] && CMD="help"

function do_check_start() {
  #check if superuser
  if [ $UID -ne 0 ]; then
    echo "Please run this script with Superuser privileges!"
    exit 1
  fi
  #check if raspberry pi 
  if [ "$raspi" != "" ]; then
    raspi_v="$(tr -d '\0' 2>/dev/null < /proc/device-tree/model)"
    local raspi_res="false"
    [[ "$raspi_v" =~ "Raspberry Pi" ]] && [[ "$raspi" =~ "all" ]] && raspi_res="true"
    [[ "$raspi_v" =~ "Raspberry Pi 3" ]] && [[ "$raspi" =~ "rpi3" ]] && raspi_res="true"
    [[ "$raspi_v" =~ "Raspberry Pi 4" ]] && [[ "$raspi" =~ "rpi4" ]] && raspi_res="true"
    [[ "$raspi_v" =~ "Raspberry Pi 5" ]] && [[ "$raspi" =~ "rpi5" ]] && raspi_res="true"
    if [ "$raspi_res" == "false" ]; then
      echo "This Device seems not to be an Raspberry Pi ($raspi)! Can not continue with this script!"
      exit 1
    fi
  fi
  #check if raspbian
  if [ "$rasos" != "" ]
  then
    rasos_v="$(lsb_release -d -s 2>/dev/null)"
    [ -f /etc/rpi-issue ] && rasos_v="Raspbian ${rasos_v}"
    local rasos_res="false"
    [[ "$rasos_v" =~ "Raspbian" ]] && [[ "$rasos" =~ "all" ]] && rasos_res="true"
    [[ "$rasos_v" =~ "Raspbian" ]] && [[ "$rasos_v" =~ "bullseye" ]] && [[ "$rasos" =~ "bullseye" ]] && rasos_res="true"
    [[ "$rasos_v" =~ "Raspbian" ]] && [[ "$rasos_v" =~ "bookworm" ]] && [[ "$rasos" =~ "bookworm" ]] && rasos_res="true"
    [[ "$rasos_v" =~ "Raspbian" ]] && [[ "$rasos_v" =~ "trixie" ]] && [[ "$rasos" =~ "trixie" ]] && rasos_res="true"
    if [ "$rasos_res" == "false" ]; then
      echo "You need to run Raspbian OS ($rasos) to run this script! Can not continue with this script!"
      exit 1
    fi
  #check cpu architecture
  if [ "$cpuarch" != "" ]; then
    cpuarch_v="$(dpkg --print-architecture 2>/dev/null)"
    if [[ ! "$cpuarch" =~ "$cpuarch_v" ]]; then
      echo "Your CPU Architecture ($cpuarch_v) is not supported! Can not continue with this script!"
      exit 1
    fi
  fi
  #check os architecture
  if [ "$bsarch" == "32" ] || [ "$bsarch" == "64" ]; then
    bsarch_v="$(getconf LONG_BIT 2>/dev/null)"
    if [ "$bsarch" != "$bsarch_v" ]; then
      echo "Your OS Architecture ($bsarch_v) is not supported! Can not continue with this script!"
      exit 1
    fi
  fi
  #check apt paks
  local apt
  local apt_res
  IFS=$' '
  if [ "${#aptpaks[@]}" != "0" ]; then
    for apt in ${aptpaks[@]}; do
      [[ ! "$(dpkg -s $apt 2>/dev/null)" =~ "Status: install" ]] && apt_res="${apt_res}${apt}, "
    done
    if [ "$apt_res" != "" ]; then
      echo "Not installed apt paks: ${apt_res%?%?}! Can not continue with this script!"
      exit 1
    fi
  fi
  unset IFS
}

function cmd_activate() {
  if command -v plymouth-set-default-theme >/dev/null; then
    if [ "$(plymouth-set-default-theme)" != "rpi-spinner" ]; then
      plymouth-set-default-theme -R rpi-spinner >/dev/null 2>&1
    fi
  elif command -v update-alternatives >/dev/null; then
    update-alternatives --install /usr/share/plymouth/themes/default.plymouth default.plymouth /usr/share/plymouth/themes/rpi-spinner/rpi-spinner.plymouth 200 >/dev/null 2>&1
    update-alternatives --set default.plymouth /usr/share/plymouth/themes/rpi-spinner/rpi-spinner.plymouth >/dev/null 2>&1
  else
    echo "No suitable command found to set plymouth theme! Can not continue with this script!"
    return 1
  fi
  echo "plymouth theme rpi-spinner activated!"
}

function cmd_deactivate() {
  if command -v plymouth-set-default-theme >/dev/null; then
    if [ "$(plymouth-set-default-theme)" == "rpi-spinner" ]; then
      plymouth-set-default-theme -R details >/dev/null 2>&1
    fi
  elif command -v update-alternatives >/dev/null; then
    update-alternatives --remove default.plymouth /usr/share/plymouth/themes/rpi-spinner/rpi-spinner.plymouth >/dev/null 2>&1
    update-alternatives --install /usr/share/plymouth/themes/default.plymouth default.plymouth /usr/share/plymouth/themes/details/details.plymouth 200 >/dev/null 2>&1
    update-alternatives --set default.plymouth /usr/share/plymouth/themes/details.plymouth >/dev/null 2>&1
  else
    echo "No suitable command found to set plymouth theme! Can not continue with this script!"
    return 1
  fi
  echo "plymouth theme rpi-spinner deactivated!"
}

function cmd_print_version() {
  echo "$SCRIPT_TITLE v$SCRIPT_VERSION"
}

function cmd_print_help() {
  echo "Usage: $SCRIPT_NAME [OPTION]"
  echo "$SCRIPT_TITLE v$SCRIPT_VERSION"
  echo " "
  echo "This is a rpi-spinner plymouth theme."
  echo " "
  echo "-a, --activate          activate splashscreen"
  echo "-d, --deactivate        deactivate splashscreen"
  echo "-v, --version           print version info and exit"
  echo "-h, --help              print this help and exit"
  echo " "
  echo "Only one option at same time is allowed!"
  echo " "
  echo "Author: aragon25 <aragon25.01@web.de>"
}

[ "$cmd" != "version" ] && [ "$cmd" != "help" ] &&  do_check_start
[[ "$cmd" == "version" ]] && cmd_print_version
[[ "$cmd" == "help" ]] && cmd_print_help
[[ "$cmd" == "activate" ]] && cmd_activate
[[ "$cmd" == "deactivate" ]] && cmd_deactivate

exit 0
