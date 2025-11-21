#!/usr/bin/sudo bash
##############################################
##                                          ##
##  build_deb-v1.2                          ##
##                                          ##
##############################################

#####################################
#    !!!INSTALL RESTRICTIONS!!!     #
#####################################
#only for raspberry pi (rpi5|rpi4|rpi3|all) can combined!
raspi="all"
#only for Raspbian OS (bookworm|bullseye|all) can combined!
rasos="bookworm|bullseye"
#only for cpu architecture (i386|armhf|amd64|arm64) can combined!
cpuarch=""
#only for os architecture (32|64) can NOT combined!
bsarch=""

#####################################
#   !!!DEBIAN PACKAGE VALUES!!!     #
#####################################
# (mandatory) A valid folder inside the scriptfolder. Contains files to copy to filesystem structure.
PAK_SRC_DIR="deb_files"
# (mandatory) build file instructions. copies a source_file from src_dir to target_file. {source_file}={target_path}/{target_filename}
PAK_SRC_FILES_CONF="
plymouth-wait.conf=etc/systemd/system/lightdm.service.d/plymouth-wait.conf
plymouth-wait.conf=etc/systemd/system/plymouth-quit.service.d/plymouth-wait.conf
plymouth-rpi-spinner.sh=usr/bin/plymouth-rpi-spinner"
# (mandatory) build dir instructions. copies a source_dir from src_dir to target_dir. {source_file}={target_path}/{target_dirname}
PAK_SRC_DIRS_CONF="
rpi-spinner=usr/share/plymouth/themes/rpi-spinner"
# (mandatory) The name of the binary package. Package names (both source and binary, see Package)
# must consist only of lower case letters (a-z), digits (0-9), plus (+) and minus (-) signs, and periods (.).
# They must be at least two characters long and must start with an alphanumeric character.
PAK_NAME="plymouth-theme-rpi-spinner"
# (mandatory) The version number of a package. The format is: [epoch:]upstream_version[-debian_revision].
PAK_VERSION="1.1-2"
# (recommended) This field represents how important it is that the user have the package installed.
# (one of 'required', 'important', 'standard' or 'optional')
PAK_PRIORITY="optional"
# (mandatory) Specifying a specific list of architectures
# "all" indicates an architecture-independent package.
# "any" matches all Debian machine architectures and is the most frequently used.
# or only for cpu architecture (i386|armhf|amd64|arm64)
PAK_ARCH="all"
# (optional) Packages can declare in their control file that they have certain relationships to other packages
# for example, that they may not be installed at the same time as certain other packages, and/or that they depend
# on the presence of others. These fields are used to declare a dependency relationship by one package on another.
# i.e. "debconf (>= 0.2.26)" or "debconf (>= 0.2.26), file" or "debconf, file"
PAK_DEPENDS="plymouth, plymouth-themes"
PAK_CONFLICTS=""
# (optional) Package installed size as integer in kilobytes (no decimals). Leave empty to let script calculate.
PAK_SIZE=""
# (optional) Additional size to add to Package installed size. Have to be integer in kilobytes (no decimals).
PAK_ADD_SIZE=""
# (mandatory) The package maintainer's name and email address. The name must come first, then the email address inside 
# angle brackets <> (in RFC822 format).
PAK_MAINTAINER="aragon25 <aragon25.01@web.de>"
# (mandatory) In a source or binary control file, the Description field contains a description of the binary package,
# consisting of two parts, the synopsis or the short description, and the long description. Do not use tab characters.
# Their effect is not predictable.
PAK_DESCRIPTION="plymouth-theme-rpi-spinner.
  This is a Raspberry pi logo spinner plymouth theme."
# (optional) The URL of the web site for this package, preferably (when applicable) the site from which the original source
# can be obtained and any additional upstream documentation or information may be found. The content of this field is a simple URL
# without any surrounding characters such as <>.
PAK_HOMEPAGE="https://www.pling.com/p/1830091"
# (optional) Changelog file
PAK_CHANGELOG='
 plymouth-theme-rpi-spinner (1.1-2) unstable; urgency=low

  * Bugfixes. (Closes: #XXXXXX)

 -- aragon25 <aragon25.01@web.de>  Tue, 01 Jul 2025 04:12:12 +0000
 
 plymouth-theme-rpi-spinner (1.1-1) unstable; urgency=low

  * Bugfixes. (Closes: #XXXXXX)

 -- aragon25 <aragon25.01@web.de>  Thu, 18 Nov 2010 17:30:32 +0000

 plymouth-theme-rpi-spinner (1.0-1) unstable; urgency=low

  * Initial release. (Closes: #XXXXXX)

 -- aragon25 <aragon25.01@web.de>  Mon, 18 Nov 2024 17:25:32 +0000'
# (optional) Copyright file
PAK_COPYRIGHT='Format: https://www.debian.org/doc/packaging-manuals/copyright-format/1.0/
Upstream-Name: plymouth-theme-rpi-spinner
Upstream-Contact: aragon25 <aragon25.01@web.de>

Files: *
Copyright: 2024 aragon25
License: MIT
  MIT License
  .
  Copyright (c) 2024 aragon25
  .
  Permission is hereby granted, free of charge, to any person obtaining a copy
  of this software and associated documentation files (the "Software"), to deal
  in the Software without restriction, including without limitation the rights
  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
  copies of the Software, and to permit persons to whom the Software is
  furnished to do so, subject to the following conditions:
  .
  The above copyright notice and this permission notice shall be included in all
  copies or substantial portions of the Software.
  .
  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
  SOFTWARE.'
# (optional) Scriptfiles
# Installation calls: preinst install -> postinst configure
# Deinstallation calls: prerm remove -> postrm remove
# Upgrade/Downgrade/Reinstall calls: prerm upgrade -> preinst upgrade -> postrm upgrade -> postinst configure
PAK_PREINST='#!/bin/bash
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
exit 0'
PAK_POSTINST='#!/bin/bash
if [ "$(plymouth-set-default-theme)" != "rpi-spinner" ]; then
  echo "Change plymouth theme to rpi-spinner ..."
  plymouth-set-default-theme -R rpi-spinner >/dev/null 2>&1
fi
systemctl daemon-reload >/dev/null 2>&1
exit 0'
PAK_PRERM='#!/bin/bash
if [ "$(plymouth-set-default-theme)" == "rpi-spinner" ] && [ "$1" == "remove" ]; then
  echo "Change plymouth theme to details ..."
  plymouth-set-default-theme -R details >/dev/null 2>&1
fi
exit 0'
PAK_POSTRM='#!/bin/bash
if [ "$1" == "remove" ]; then
  systemctl daemon-reload >/dev/null 2>&1
fi
exit 0'









#####################################
### DO NOT CHANGE BELOW THIS LINE ###
#####################################

SCRIPT_DIR="$(readlink -f "$0")"
SCRIPT_NAME="$(basename "$SCRIPT_DIR")"
SCRIPT_DIR="$(dirname "$SCRIPT_DIR")"
BUILD_DIR="${SCRIPT_DIR}/build"
RELEASE_DIR="${SCRIPT_DIR}/release"
DEB_NAME=${PAK_NAME}_${PAK_VERSION}_${PAK_ARCH}
DEB_DIR="${BUILD_DIR}/${DEB_NAME}"
DEB_SRC="${SCRIPT_DIR}/${PAK_SRC_DIR}"
USERID="${SUDO_UID:-$UID}"
GROUPID="$(id -g $USERID)"
EXITCODE=0

function config_read_input_key(){ # input, key -> value
  local val=$( (echo "${1}" | grep -E "^${2}=" -m 1 - || echo "VAR=__UNDEFINED__") | head -n 1 | cut -d '=' -f 2-)
  val=$(echo "${val}" | sed 's/ *$//g' | sed 's/^ *//g')
  printf -- "%s" "${val}"
}

function config_read_input_line_opt(){ # input, linenum -> optionname
  local var=$( echo "${1}" | awk "NR==${2}" | head -n 1 | cut -d '=' -f 1 )
  var=$(echo "${var}" | sed 's/ *$//g' | sed 's/^ *//g')
  [ "${var}" == "" ] && var="__UNDEFINED__"
  printf -- "%s" "${var}"
}

function config_read_input_line_val(){ # input, linenum -> value
  local var=$( echo "${1}" | awk "NR==${2}" | head -n 1 | cut -d '=' -f 2- )
  var=$(echo "${var}" | sed 's/ *$//g' | sed 's/^ *//g')
  [ "${var}" == "" ] && var="__UNDEFINED__"
  printf -- "%s" "${var}"
}

function clean_build_dir() {
  echo "Cleanup build dirs..."
  rm -rf "${BUILD_DIR}"
}

function create_build_dir() {
  echo "Create build dir structure..."
  mkdir -p "${DEB_DIR}/DEBIAN"
  mkdir -p "${RELEASE_DIR}"
}

function check_commands () {
  echo "Check prereqs..."
  local SUCCESSCODE="TRUE"
  local cmd=""
  local resultstring=""
  for cmd in grep cut sed cat tee dpkg-deb; do
    if ! command -v $cmd >/dev/null; then
      resultstring="$cmd $resultstring"
      SUCCESSCODE="FALSE"
    fi
  done
  if [ "${SUCCESSCODE}" != "TRUE" ]; then
    echo "\"$resultstring\" command(s) not found! abort."
    return 1
  else
    return 0
  fi
}

function check_src() {
  echo "Check source..."
  local SUCCESSCODE="TRUE"
  PAK_NAME="$(basename "$PAK_NAME")"
  PAK_NAME="$(echo "$PAK_NAME" | cut -d' ' -f1)"
  PAK_VERSION="$(echo "$PAK_VERSION" | cut -d' ' -f1)"
  PAK_ARCH="$(basename "$PAK_ARCH")"
  PAK_ARCH="$(echo "$PAK_ARCH" | cut -d' ' -f1)"
  PAK_SIZE="${PAK_SIZE//[^0-9]/}"
  PAK_ADD_SIZE="${PAK_ADD_SIZE//[^0-9]/}"
  if [ "${PAK_NAME}" == "" ]; then
    echo "PAK_NAME value have to be set! abort."
    SUCCESSCODE="FALSE"
  fi
  if [ "${PAK_ARCH}" == "" ]; then
    echo "PAK_ARCH value have to be set! abort."
    SUCCESSCODE="FALSE"
  fi
  if [ "${PAK_MAINTAINER}" == "" ]; then
    echo "PAK_MAINTAINER value have to be set! abort."
    SUCCESSCODE="FALSE"
  fi
  if [ "${PAK_DESCRIPTION}" == "" ]; then
    echo "PAK_DESCRIPTION value have to be set! abort."
    SUCCESSCODE="FALSE"
  fi
  if [ ! -d "${DEB_SRC}" ] || [ "$PAK_SRC_DIR" == "" ]; then
    echo "PAK_SRC_DIR value have to be set to a valid folder inside scriptfolder! abort."
    SUCCESSCODE="FALSE"
  fi
  if [ "${PAK_VERSION}" == "" ]; then
    echo "PAK_VERSION value have to be set! abort."
    SUCCESSCODE="FALSE"
  fi
  [ "${PAK_PRIORITY}" != "required" ] && [ "${PAK_PRIORITY}" != "important" ] && [ "${PAK_PRIORITY}" != "standard" ] && 
    [ "${PAK_PRIORITY}" != "optional" ] && PAK_PRIORITY="optional"
  [ "${SUCCESSCODE}" != "TRUE" ] && return 1 || return 0
}

function set_final_file_perms() {
  #chown -Rf $(logname):$(groups $(logname) | awk '{print $3}') "${BUILD_DIR}" >/dev/null 2>&1
  #chown -Rf $(logname):$(groups $(logname) | awk '{print $3}') "${RELEASE_DIR}" >/dev/null 2>&1
  chown -Rf ${USERID}:${GROUPID} "${BUILD_DIR}" >/dev/null 2>&1
  chown -Rf ${USERID}:${GROUPID} "${RELEASE_DIR}" >/dev/null 2>&1
}

function set_src_file_perms() {
  echo "Set source files perms..."
  local filetype
  local entry
  local test
  IFS=$'\n'
  test=($(find "${DEB_DIR}"))
  if [ "${#test[@]}" != "0" ]; then
    for entry in ${test[@]}; do
      chown -f 0:0 "$entry"
      if [ -f "$entry" ] && [ ! -L "$entry" ]; then
        filetype=$(file -b --mime-type "$entry" 2>/dev/null)
        if [[ "$filetype" =~ "executable" ]] || [[ "$filetype" =~ "script" ]] || 
           [[ "$entry" == *".desktop" ]] || [[ "$entry" == *".sh" ]]|| [[ "$entry" == *".py" ]]; then
          chmod -f 755 "$entry"
        else
          chmod -f 644 "$entry"
        fi
      elif [ -d "$entry" ] && [ ! -L "$entry" ]; then
        chmod -f 755 "$entry"
      fi
    done
  fi
  unset IFS
}

function create_control() {
  echo "Create control file..."
  echo "Package: ${PAK_NAME}" > "${DEB_DIR}/DEBIAN/control"
  echo "Version: ${PAK_VERSION}" >> "${DEB_DIR}/DEBIAN/control"
  echo "Priority: ${PAK_PRIORITY}" >> "${DEB_DIR}/DEBIAN/control"
  echo "Architecture: ${PAK_ARCH}" >> "${DEB_DIR}/DEBIAN/control"
  echo "Maintainer: ${PAK_MAINTAINER}" >> "${DEB_DIR}/DEBIAN/control"
  echo "Description: ${PAK_DESCRIPTION}" >> "${DEB_DIR}/DEBIAN/control"
  [ "${PAK_HOMEPAGE}" != "" ] && echo "Homepage: ${PAK_HOMEPAGE}" >> "${DEB_DIR}/DEBIAN/control"
  [ "${PAK_DEPENDS}" != "" ] && echo "Depends: ${PAK_DEPENDS}" >> "${DEB_DIR}/DEBIAN/control"
  [ "${PAK_CONFLICTS}" != "" ] && echo "Conflicts: ${PAK_CONFLICTS}" >> "${DEB_DIR}/DEBIAN/control"
  [ "${PAK_SIZE}" == "" ] && PAK_SIZE="$(du -sk --exclude=DEBIAN ${DEB_DIR} | awk '{print $1}')"
  [ "${PAK_ADD_SIZE}" != "" ] && PAK_SIZE=$((PAK_SIZE + PAK_ADD_SIZE))
  [ "${PAK_SIZE}" != "" ] && echo "Installed-Size: ${PAK_SIZE}" >> "${DEB_DIR}/DEBIAN/control"
}

function create_scripts() {
  echo "Create control scripts..."
  cat <<EOF | sudo tee "${DEB_DIR}/DEBIAN/preinst" >/dev/null 2>&1
#!/bin/bash
raspi="$raspi"
rasos="$rasos"
cpuarch="$cpuarch"
bsarch="$bsarch"
SCRIPTDIR="\$(readlink -f "\$0")"
SCRIPTDIR="\$(dirname "\$SCRIPTDIR")"

#check if raspberry pi 
if [ "\$raspi" != "" ]; then
  raspi_v="\$(tr -d '\0' 2>/dev/null < /proc/device-tree/model)"
  raspi_res="false"
  [[ "\$raspi_v" =~ "Raspberry Pi" ]] && [[ "\$raspi" =~ "all" ]] && raspi_res="true"
  [[ "\$raspi_v" =~ "Raspberry Pi 3" ]] && [[ "\$raspi" =~ "rpi3" ]] && raspi_res="true"
  [[ "\$raspi_v" =~ "Raspberry Pi 4" ]] && [[ "\$raspi" =~ "rpi4" ]] && raspi_res="true"
  [[ "\$raspi_v" =~ "Raspberry Pi 5" ]] && [[ "\$raspi" =~ "rpi5" ]] && raspi_res="true"
  if [ "\$raspi_res" == "false" ]; then
    echo "This Device seems not to be an Raspberry Pi (\$raspi)! Can not continue with this installer!"
    exit 1
  fi
fi
#check if raspbian
if [ "\$rasos" != "" ]
then
  rasos_v="\$(lsb_release -d -s 2>/dev/null)"
  [ -f /etc/rpi-issue ] && rasos_v="Raspbian \${rasos_v}"
  rasos_res="false"
  [[ "\$rasos_v" =~ "Raspbian" ]] && [[ "\$rasos" =~ "all" ]] && rasos_res="true"
  [[ "\$rasos_v" =~ "Raspbian" ]] && [[ "\$rasos_v" =~ "bullseye" ]] && [[ "\$rasos" =~ "bullseye" ]] && rasos_res="true"
  [[ "\$rasos_v" =~ "Raspbian" ]] && [[ "\$rasos_v" =~ "bookworm" ]] && [[ "\$rasos" =~ "bookworm" ]] && rasos_res="true"
  if [ "\$rasos_res" == "false" ]; then
    echo "You need to run Raspbian OS (\$rasos) to install! Can not continue with this installer!"
    exit 1
  fi
fi
#check cpu architecture
if [ "\$cpuarch" != "" ]; then
  cpuarch_v="\$(dpkg --print-architecture 2>/dev/null)"
  if [[ ! "\$cpuarch" =~ "\$cpuarch_v" ]]; then
    echo "Your CPU Architecture (\$cpuarch_v) is not supported! Can not continue with this installer!"
    exit 1
  fi
fi
#check os architecture
if [ "\$bsarch" == "32" ] || [ "\$bsarch" == "64" ]; then
  bsarch_v="\$(getconf LONG_BIT 2>/dev/null)"
  if [ "\$bsarch" != "\$bsarch_v" ]; then
    echo "Your OS Architecture (\$bsarch_v) is not supported! Can not continue with this installer!"
    exit 1
  fi
fi
#run preinst_user script
[ -e "\${SCRIPTDIR}/preinst_user" ] && "\${SCRIPTDIR}/preinst_user" \$@
exit \$?
EOF
if [ "$PAK_PREINST" != "" ]; then
  cat <<EOF | sudo tee "${DEB_DIR}/DEBIAN/preinst_user" >/dev/null 2>&1
$PAK_PREINST
EOF
fi
if [ "$PAK_POSTINST" != "" ]; then
  cat <<EOF | sudo tee "${DEB_DIR}/DEBIAN/postinst" >/dev/null 2>&1
$PAK_POSTINST
EOF
fi
if [ "$PAK_PRERM" != "" ]; then
  cat <<EOF | sudo tee "${DEB_DIR}/DEBIAN/prerm" >/dev/null 2>&1
$PAK_PRERM
EOF
fi
if [ "$PAK_POSTRM" != "" ]; then
  cat <<EOF | sudo tee "${DEB_DIR}/DEBIAN/postrm" >/dev/null 2>&1
$PAK_POSTRM
EOF
fi
if [ "$PAK_COPYRIGHT" != "" ]; then
  cat <<EOF | sudo tee "${DEB_DIR}/DEBIAN/copyright" >/dev/null 2>&1
$PAK_COPYRIGHT
EOF
fi
if [ "$PAK_CHANGELOG" != "" ]; then
  cat <<EOF | sudo tee "${DEB_DIR}/DEBIAN/changelog" >/dev/null 2>&1
$PAK_CHANGELOG
EOF
fi
}

function build_src_dir() {
  echo "Build src dir..."
  local SUCCESSCODE="TRUE"
  local test
  local entry
  local cp_to_path
  local lines
  local line
  IFS=$'\n'
  test=($(find "${DEB_SRC}" -maxdepth 1 -mindepth 1))
  if [ "${#test[@]}" != "0" ]; then
    for entry in ${test[@]}; do
      if [ -f "$entry" ] || [ -L "$entry" ]; then
        cp_to_path="$(config_read_input_key "$PAK_SRC_FILES_CONF" "$(basename "$entry")")"
        [ "$cp_to_path" == "" ] && cp_to_path="__UNDEFINED__"
        if [ "$cp_to_path" == "__UNDEFINED__" ]; then
          echo "file '$(basename "$entry")' not configured!"
          SUCCESSCODE="FALSE"
        fi
      elif [ -f "$(dirname "$entry")/$(basename "$entry" "_payload").sh" ]; then
        cp_to_path="$(config_read_input_key "$PAK_SRC_FILES_CONF" "$(basename "$entry" "_payload").sh")"
        [ "$cp_to_path" == "" ] && cp_to_path="__UNDEFINED__"
        if [ "$cp_to_path" == "__UNDEFINED__" ]; then
          echo "payload dir '$(basename "$entry")' has no script!"
          SUCCESSCODE="FALSE"
        fi
      elif [ -d "$entry" ]; then
        cp_to_path="$(config_read_input_key "$PAK_SRC_DIRS_CONF" "$(basename "$entry")")"
        [ "$cp_to_path" == "" ] && cp_to_path="__UNDEFINED__"
        if [ "$cp_to_path" == "__UNDEFINED__" ]; then
          echo "dir '$(basename "$entry")' not configured!"
          SUCCESSCODE="FALSE"
        fi
      fi
    done
  fi
  unset IFS
  if [ "$SUCCESSCODE" != "FALSE" ]; then
    line=1
    lines=$(echo "$PAK_SRC_FILES_CONF" | wc -l)
    while [ $line -le $lines ] && [ "$SUCCESSCODE" != "FALSE" ]
    do
      if [ "$(echo "$PAK_SRC_FILES_CONF" | awk "NR==$line" | sed 's/ *$//g' | sed 's/^ *//g')" != "" ]; then
        entry="${DEB_SRC}/$(config_read_input_line_opt "$PAK_SRC_FILES_CONF" $line)"
        if [ -f "$entry" ] || [ -L "$entry" ]; then
          cp_to_path="$(config_read_input_line_val "$PAK_SRC_FILES_CONF" $line)"
          [ "$cp_to_path" == "" ] && cp_to_path="__UNDEFINED__"
          cp_to_path="$(echo "$cp_to_path" | sed "s#^/\(.*\)#\1#" | sed "s#\(.*\)/\$#\1#")"
          if [ "$cp_to_path" != "__UNDEFINED__" ]; then
            mkdir -p "${DEB_DIR}/$(dirname "$cp_to_path")" >/dev/null 2>&1
            cp -af "${entry}" "${DEB_DIR}/${cp_to_path}" >/dev/null 2>&1
            if [ $? -ne 0 ]; then 
                echo "'$(basename "$entry")' copy file failed!"
                SUCCESSCODE="FALSE"
            fi
            entry="$(dirname "$entry")/$(basename "$entry" ".sh")_payload"
            if [ -d "$entry" ] && [ "$SUCCESSCODE" != "FALSE" ]; then
              cp_to_path="$(dirname "$cp_to_path")/$(basename "$cp_to_path" ".sh")_payload"
              mkdir -p "${DEB_DIR}/$(dirname "$cp_to_path")" >/dev/null 2>&1
              rm -rf "${DEB_DIR}/${cp_to_path}" >/dev/null 2>&1
              cp -arf "${entry}" "${DEB_DIR}/${cp_to_path}" >/dev/null 2>&1
              if [ $? -ne 0 ]; then 
                echo "'$(basename "$entry")' copy payload dir failed!"
                SUCCESSCODE="FALSE"
              fi
            fi
          else
            echo "'$(basename "$entry")' file config failure!"
            SUCCESSCODE="FALSE"
          fi
        else
          echo "'$(basename "$entry")' file not found!"
          SUCCESSCODE="FALSE"
        fi
      fi
      line=$(( $line + 1 ))
    done
  fi
  if [ "$SUCCESSCODE" != "FALSE" ]; then
    line=1
    lines=$(echo "$PAK_SRC_DIRS_CONF" | wc -l)
    while [ $line -le $lines ] && [ "$SUCCESSCODE" != "FALSE" ]
    do
      if [ "$(echo "$PAK_SRC_DIRS_CONF" | awk "NR==$line" | sed 's/ *$//g' | sed 's/^ *//g')" != "" ]; then
        entry="${DEB_SRC}/$(config_read_input_line_opt "$PAK_SRC_DIRS_CONF" $line)"
        if [ -d "$entry" ]; then
          cp_to_path=$(config_read_input_line_val "$PAK_SRC_DIRS_CONF" $line)
          [ "$cp_to_path" == "" ] && cp_to_path="__UNDEFINED__"
          cp_to_path=$(echo "$cp_to_path" | sed "s#^/\(.*\)#\1#" | sed "s#\(.*\)/\$#\1#")
          if [ "$cp_to_path" != "__UNDEFINED__" ]; then
            mkdir -p "${DEB_DIR}/$(dirname "$cp_to_path")" >/dev/null 2>&1
            rm -rf "${DEB_DIR}/${cp_to_path}" >/dev/null 2>&1
            cp -arf "${entry}" "${DEB_DIR}/${cp_to_path}" >/dev/null 2>&1
            if [ $? -ne 0 ]; then 
                echo "'$(basename "$entry")' copy dir failed!"
                SUCCESSCODE="FALSE"
            fi
          else
            echo "'$(basename "$entry")' dir config failure!"
            SUCCESSCODE="FALSE"
          fi
        else
          echo "'$(basename "$entry")' dir not found!"
          SUCCESSCODE="FALSE"
        fi
      fi
      line=$(( $line + 1 ))
    done
  fi
  if [ "$SUCCESSCODE" == "FALSE" ]; then
    set_final_file_perms
    echo "Build src dir error!"
    return 1
  fi
  return 0
}

function pack_payloads() {
  echo "Pack file payloads..."
  local SUCCESSCODE="TRUE"
  local entry
  local test
  IFS=$'\n'
  test=($(find "${DEB_DIR}" -mindepth 1))
  if [ "${#test[@]}" != "0" ]; then
    for entry in ${test[@]}; do
      if [ -f "$entry" ] && [ -d "$(dirname "$entry")/$(basename "$entry" ".sh")_payload" ]; then
        chmod +x "$entry"
        "$entry" --payload_pack >/dev/null 2>&1
        if [ $? -ne 0 ]; then
          entry="'$(basename "$entry")' --payload_pack!"
          SUCCESSCODE="FALSE"
        fi
      fi
      [ "$SUCCESSCODE" == "FALSE" ] && break
    done
  fi
  unset IFS
  if [ "$SUCCESSCODE" == "FALSE" ]; then
    set_final_file_perms
    echo "Pack file payload error: $entry"
    return 1
  fi
  return 0
}

function build_deb() {
  echo "Build deb package..."
  local SUCCESSCODE="TRUE"
  rm -f "${RELEASE_DIR}/${DEB_NAME}.deb"
  dpkg-deb -Zxz --build "${DEB_DIR}" "${RELEASE_DIR}/${DEB_NAME}.deb" >/dev/null 2>&1
  if [ $? -ne 0 ]; then
    set_final_file_perms
    echo "build deb package error! abort."
    SUCCESSCODE="FALSE"
  fi
  [ "${SUCCESSCODE}" != "TRUE" ] && return 1 || return 0
}

clean_build_dir
check_commands || exit 1
check_src || exit 1
create_build_dir
build_src_dir || exit 1
pack_payloads || exit 1
create_scripts
create_control
set_src_file_perms
build_deb || exit 1
set_final_file_perms
echo "build deb package finished successfully!"
