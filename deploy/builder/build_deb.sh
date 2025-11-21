#!/usr/bin/sudo bash
##############################################
##                                          ##
##  build_deb (deb builder)                 ##
##                                          ##
##############################################

SCRIPT_TITLE="build_deb (deb builder)"
SCRIPT_VERSION="1.4"
SCRIPT_PATH="$(readlink -f "$0")"
SCRIPT_NAME="$(basename "$SCRIPT_PATH")"
SCRIPT_DIR="$(dirname "$SCRIPT_PATH")"
SCRIPT_BASENAME="$(basename "$SCRIPT_PATH" ".sh")"
CONFIG_FILE="${SCRIPT_DIR}/${SCRIPT_BASENAME}.config"
USERID="${SUDO_UID:-$UID}"
GROUPID="$(id -g $USERID)"
EXITCODE=0

#check commands
for i in "$@"
do
  case $i in
    -t|--test)
    TEST_DEB="y";
    ;;
    -v|--version)
    [ -z "$CMD" ] && CMD="version" || CMD="help";
    ;;
    -h|--help)
    CMD="help"
    ;;
    *)
    [ -z "$CMD" ] && CMD="$i" || CMD="help";
    ;;
  esac
done

function is_valid_filepath() {
  local path="$1"
  [[ -z "$path" ]] && return 1
  [[ "$path" != /* ]] && return 1
  [[ "$path" == *'//' ]] && return 1
  [[ "$path" != "/" ]] && path="${path%/}"
  local name="$(basename -- "$path")"
  [[ "$name" =~ ^[a-zA-Z0-9._\ -]+$ ]] || return 1
  name=$(echo "$name" | xargs)
  [[ -z "$name" ]] && return 1
  return 0
}

function check_entries(){ # cfg_name, cfg_value, possible_values
  local cfg_name="$1"
  local cfg_value="$2"
  local allowed_values="$3"
  local entry=""
  local entries=()
  [[ -z "$cfg_value" ]] && return 0
  IFS='|' read -ra entries <<< "$cfg_value"
  for entry in "${entries[@]}"; do
    if [[ ! "|$allowed_values|" == *"|$entry|"* ]]; then
      echo "ERROR: '$entry' is not valid for $cfg_name!"
    fi
  done
}

function check_cfg_paths() {
  local line=""
  local src=""
  local dest=""
  local file_ok=0
  local dir_ok=0
  local errors=0
  if [[ -n "$CFG_FILES_CONF" ]]; then
    while IFS= read -r line; do
      [[ -z "$line" ]] && continue
      if [[ "$line" != *=* ]]; then
        echo "ERROR: Invalid line in CFG_FILES_CONF: '$line' (missing '=')"
        ((errors++))
      fi
      src="${line%%=*}"
      if [[ ! -f "$src" ]]; then
        echo "ERROR: Source file '$src' not found"
        ((errors++))
      fi
      dest="${line#*=}"
      if ! is_valid_filepath "$dest"; then
        echo "ERROR: Destination filepath '$dest' not valid"
        ((errors++))
      fi
      ((file_ok++))
    done <<< "$CFG_FILES_CONF"
  fi
  if [[ -n "$CFG_DIRS_CONF" ]]; then
    while IFS= read -r line; do
      [[ -z "$line" ]] && continue
      if [[ "$line" != *=* ]]; then
        echo "ERROR: Invalid line in CFG_DIRS_CONF: '$line' (missing '=')"
        ((errors++))
      fi
      src="${line%%=*}"
      if [[ ! -d "$src" ]]; then
        echo "ERROR: Source directory '$src' not found"
        ((errors++))
      fi
      dest="${line#*=}"
      if ! is_valid_filepath "$dest"; then
        echo "ERROR: Destination dirpath '$dest' not valid"
        ((errors++))
      fi
      ((dir_ok++))
    done <<< "$CFG_DIRS_CONF"
  fi
  [ "$errors" != "0" ] && return 1
  if (( file_ok == 0 && dir_ok == 0 )); then
    echo "ERROR: CFG_FILES_CONF and CFG_DIRS_CONF are both empty or invalid. At least one must be set!"
    return 1
  fi
}

function check_cfg_name() {
  if [[ -z "$CFG_NAME" ]]; then
    echo "ERROR: CFG_NAME is empty!"
    echo "  → Must be at least 2 characters, lowercase a-z, 0-9, +, -, . and start with letter or digit."
    return 1
  fi
  if [[ ! "$CFG_NAME" =~ ^[a-z0-9][a-z0-9+.-]{1,}$ ]]; then
    echo "ERROR: CFG_NAME='$CFG_NAME' is invalid!"
    echo "  → Must be at least 2 characters, lowercase a-z, 0-9, +, -, . and start with letter or digit."
    return 1
  fi
}

function check_cfg_version() {
  if [[ -z "$CFG_VERSION" ]]; then
    echo "ERROR: CFG_VERSION is empty!"
    echo "  → Expected format: [epoch:]upstream_version[-debian_revision]"
    return 1
  fi
  if [[ ! "$CFG_VERSION" =~ ^([0-9]+:)?[a-zA-Z0-9.+~]+(-[a-zA-Z0-9.+~]+)?$ ]]; then
    echo "ERROR: CFG_VERSION='$CFG_VERSION' is invalid!"
    echo "  → Expected format: [epoch:]upstream_version[-debian_revision]"
    return 1
  fi
}

function check_cfg_priority() {
  if [[ -z "$CFG_PRIORITY" ]]; then
    echo "ERROR: CFG_PRIORITY is empty!"
    echo "  → Must be one of: required, important, standard, optional"
    return 1
  fi
  case "$CFG_PRIORITY" in
    required|important|standard|optional)
      # valid
      ;;
    *)
      echo "ERROR: CFG_PRIORITY='$CFG_PRIORITY' is invalid!"
      echo "  → Must be one of: required, important, standard, optional"
      return 1
      ;;
  esac
}

function check_cfg_arch() {
  if [[ -z "$CFG_ARCH" ]]; then
    echo "ERROR: CFG_ARCH is empty!"
    echo "  → Must be one of: all, any, amd64, arm64, i386, armhf"
    return 1
  fi
  case "$CFG_ARCH" in
    all|any|amd64|arm64|i386|armhf)
      # gültig
      ;;
    *)
      echo "ERROR: CFG_ARCH='$CFG_ARCH' is invalid!"
      echo "  → Must be one of: all, any, amd64, arm64, i386, armhf"
      return 1
      ;;
  esac
}

function check_cfg_depends() { # cfg_name, cfg_value
  local cfg_name="$1"
  local cfg_value="$2"
  local entry=""
  local entries=()
  local regex='^[a-z0-9][a-z0-9+.-]*(\ \((>=|<=|=|>>|<<)\ [^()[:space:]]+\))?$'
  [[ -z "$cfg_value" ]] && return 0 
  IFS=',' read -ra entries <<< "$cfg_value"
  for entry in "${entries[@]}"; do
    entry=$(echo "${entry}" | xargs)
    if ! [[ $entry =~ $regex ]]; then
      echo "ERROR: $cfg_name='$entry' is invalid!"
      echo "  → Must be: name [ (op version) ], separated by commas"
      return 1
    fi
  done
}

function check_cfg_size() { # cfg_name, cfg_value
  local cfg_name="$1"
  local cfg_value="$2"
  [[ -z "$cfg_value" ]] && return 0
  if ! [[ "$cfg_value" =~ ^[0-9]+$ ]]; then
    echo "ERROR: $cfg_name='$cfg_value' is invalid!"
    echo "  → Must be a non-negative integer (in kilobytes), no decimals."
    return 1
  fi
}

function check_cfg_maintainer() {
  local regex='^[^<>]+<[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}>$'
  if [[ -z "$CFG_MAINTAINER" ]]; then
    echo "ERROR: CFG_MAINTAINER is empty!"
    echo "  → Must be in the format: Name <email@example.com>"
    return 1
  fi
  if ! [[ "$CFG_MAINTAINER" =~ $regex ]]; then
    echo "ERROR: CFG_MAINTAINER='$CFG_MAINTAINER' is invalid!"
    echo "  → Expected format: Full Name <email@example.com>"
    return 1
  fi
}

function check_cfg_description() {
  if [[ -z "$CFG_DESCRIPTION" ]]; then
    echo "ERROR: CFG_DESCRIPTION is empty!"
    echo "  → Must contain a short and long description."
    return 1
  fi
  if echo "$CFG_DESCRIPTION" | grep -qP '\t'; then
    echo "ERROR: CFG_DESCRIPTION contains tab characters!"
    echo "  → Do not use tabs. Use spaces for indentation."
    return 1
  fi
}

function check_cfg_homepage() {
  #local regex='^https?://[a-zA-Z0-9._~:/?#\[\]@!$&'"'"'()*+,;=%-]+$'
  local regex='^https?://[^[:space:]<>"]+$'
  [[ -z "$CFG_HOMEPAGE" ]] && return 0 
  if ! [[ "$CFG_HOMEPAGE" =~ $regex ]]; then
    echo "ERROR: CFG_HOMEPAGE='$CFG_HOMEPAGE' is invalid!"
    echo "  → Must be a valid URL starting with http:// or https://, without surrounding characters."
    return 1
  fi
}

function check_cfg_changelog_string() {
  local regex='^[a-z0-9][a-z0-9+.-]+ \([^)]+\) [a-zA-Z0-9.-]+; urgency=[a-z]+$'
  [[ -z "$CFG_CHANGELOG_STRING" ]] && return 0 
  local first_line=$(echo "$CFG_CHANGELOG_STRING" | head -n 1)
  if ! [[ "$first_line" =~ $regex ]]; then
    echo "ERROR: CFG_CHANGELOG_STRING has an invalid first changelog line!"
    echo "  → Must match: <package> (<version>) <distribution>; urgency=<level>"
    return 1
  fi
}

function check_cfg_changelog_file_path() {
  [[ -z "$CFG_CHANGELOG_FILE_PATH" ]] && return 0 
  if [[ ! -f "$CFG_CHANGELOG_FILE_PATH" ]]; then
    echo "ERROR: CFG_CHANGELOG_FILE_PATH='$CFG_CHANGELOG_FILE_PATH' is not a valid file!"
    echo "  → Must be a readable changelog file in 'Keep a Changelog' format."
    return 1
  fi
  if ! grep -qE '^## \[[0-9]+\.[0-9]+.*\] - [0-9]{4}-[0-9]{2}-[0-9]{2}' "$CFG_CHANGELOG_FILE_PATH"; then
    echo "ERROR: CFG_CHANGELOG_FILE_PATH does not appear to follow Keep a Changelog format!"
    echo "  → Expected lines like: ## [1.0.0] - 2025-08-03"
    return 1
  fi
}

function check_cfg_copyright() {
  [[ -z "$CFG_COPYRIGHT_STRING" ]] && return 0 
  local required_fields=("Format:" "Files:" "Copyright:" "License:")
  for field in "${required_fields[@]}"; do
    if ! grep -q "^$field" <<< "$CFG_COPYRIGHT_STRING"; then
      echo "ERROR: CFG_COPYRIGHT_STRING is missing required field: $field"
      echo "  → Must follow Debian copyright format 1.0"
      return 1
    fi
  done
}

function check_cfg_copyright_file_path() {
  [[ -z "$CFG_COPYRIGHT_FILE_PATH" ]] && return 0
  if [[ ! -f "$CFG_COPYRIGHT_FILE_PATH" ]]; then
    echo "ERROR: CFG_COPYRIGHT_FILE_PATH='$CFG_COPYRIGHT_FILE_PATH' is not a valid file!"
    echo "  → Must be a path to an existing license file."
    return 1
  fi
}

function check_script_entry() { # cfg_name, cfg_value
  local cfg_name="$1"
  local cfg_value="$2"
  local regex='^#! */bin/(ba)?sh'
  [[ -z "$cfg_value" ]] && return 0
  if [[ -f "$cfg_value" ]]; then
    local first_line=$(head -n 1 "$cfg_value")
    if [[ "$first_line" =~ $regex ]]; then
      return 0
    else
      echo "ERROR: File '$cfg_value' in $cfg_name does not start with valid shebang!"
      echo "  → Must begin with: #!/bin/bash or #!/bin/sh"
      return 1
    fi
  fi
  if echo "$cfg_value" | grep -qE '^#! */bin/(ba)?sh'; then
    return 0
  fi
  echo "ERROR: $cfg_name is not a valid script!"
  echo "  → Must be either a valid file with shebang or inline script text starting with #!/bin/bash"
  return 1
}

function check_cfg_build_dir() {
  [[ -z "$CFG_BUILD_DIR" ]] && return 0
  if [[ ! -d "$CFG_BUILD_DIR" ]]; then
    echo "ERROR: CFG_BUILD_DIR='$CFG_BUILD_DIR' is not a valid directory!"
    echo "  → Must be an existing directory path."
    return 1
  fi
}

function check_cfg_release_dir() {
  [[ -z "$CFG_RELEASE_DIR"  ]] && return 0
  if [[ ! -d "$CFG_RELEASE_DIR"  ]]; then
    echo "ERROR: CFG_RELEASE_DIR ='$CFG_RELEASE_DIR' is not a valid directory!"
    echo "  → Must be an existing directory path."
    return 1
  fi
}

function check_cfg_deb_base_file_name() {
  [[ -z "$CFG_DEB_BASE_FILE_NAME" ]] && return 0
  if [[ "$CFG_DEB_BASE_FILE_NAME" =~ [^a-zA-Z0-9._+-] ]]; then
    echo "ERROR: CFG_DEB_BASE_FILE_NAME='$CFG_DEB_BASE_FILE_NAME' contains invalid characters!"
    echo "  → Only letters, digits, dot (.), dash (-), underscore (_), and plus (+) are allowed."
    return 1
  fi
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

function config_read_check_file(){
  echo "Read and test config file..."
  if [ ! -f "${CONFIG_FILE}" ]; then
    echo "ERROR: config file: '${CONFIG_FILE}' not found! abort."
    exit 1
  fi
  source "${CONFIG_FILE}"
  local SUCCESSCODE="TRUE"
  check_entries "CFG_RES_RAS_PI" "$CFG_RES_RAS_PI" "rpi5|rpi4|rpi3|all" || SUCCESSCODE="FALSE"
  check_entries "CFG_RES_RAS_OS" "$CFG_RES_RAS_OS" "bookworm|bullseye|all" || SUCCESSCODE="FALSE"
  check_entries "CFG_RES_CPU_ARCH" "$CFG_RES_CPU_ARCH" "i386|armhf|amd64|arm64" || SUCCESSCODE="FALSE"
  check_entries "CFG_RES_OS_ARCH" "$CFG_RES_OS_ARCH" "32|64" || SUCCESSCODE="FALSE"
  check_cfg_paths || SUCCESSCODE="FALSE"
  check_cfg_name || SUCCESSCODE="FALSE"
  check_cfg_version || SUCCESSCODE="FALSE"
  check_cfg_priority || SUCCESSCODE="FALSE"
  check_cfg_arch || SUCCESSCODE="FALSE"
  check_cfg_depends "CFG_DEPENDS" "$CFG_DEPENDS" || SUCCESSCODE="FALSE"
  check_cfg_depends "CFG_CONFLICTS" "$CFG_CONFLICTS" || SUCCESSCODE="FALSE"
  check_cfg_size "CFG_SIZE" "$CFG_SIZE" || SUCCESSCODE="FALSE"
  check_cfg_size "CFG_ADD_SIZE" "$CFG_ADD_SIZE" || SUCCESSCODE="FALSE"
  check_cfg_maintainer || SUCCESSCODE="FALSE"
  check_cfg_description || SUCCESSCODE="FALSE"
  check_cfg_homepage || SUCCESSCODE="FALSE"
  check_cfg_changelog_string || SUCCESSCODE="FALSE"
  check_cfg_changelog_file_path || SUCCESSCODE="FALSE"
  check_cfg_copyright || SUCCESSCODE="FALSE"
  check_cfg_copyright_file_path || SUCCESSCODE="FALSE"
  check_script_entry "CFG_PREINST" "$CFG_PREINST" || SUCCESSCODE="FALSE"
  check_script_entry "CFG_POSTINST" "$CFG_POSTINST" || SUCCESSCODE="FALSE"
  check_script_entry "CFG_PRERM" "$CFG_PRERM" || SUCCESSCODE="FALSE"
  check_script_entry "CFG_POSTRM" "$CFG_POSTRM" || SUCCESSCODE="FALSE"
  check_cfg_build_dir || SUCCESSCODE="FALSE"
  check_cfg_release_dir || SUCCESSCODE="FALSE"
  check_cfg_deb_base_file_name || SUCCESSCODE="FALSE"
  [[ -n "$CFG_BUILD_DIR" ]] && BUILD_DIR="$CFG_BUILD_DIR/deb_build" || BUILD_DIR="/tmp/deb_build"
  [[ -n "$CFG_RELEASE_DIR" ]] && RELEASE_DIR="$CFG_RELEASE_DIR" || RELEASE_DIR="./release"
  [[ -n "$CFG_DEB_BASE_FILE_NAME" ]] && DEB_BASE_FILE_NAME="$CFG_DEB_BASE_FILE_NAME" || DEB_BASE_FILE_NAME="${CFG_NAME}_${CFG_VERSION}_${CFG_ARCH}"
  [[ -n "$TEST_DEB" ]] && DEB_BASE_FILE_NAME="${DEB_BASE_FILE_NAME}_test"
  [ "${SUCCESSCODE}" != "TRUE" ] && return 1 || return 0
}

function clean_build_dir() {
  echo "Cleanup build dir..."
  rm -rf "${BUILD_DIR}" >/dev/null 2>&1
  mkdir -p "${BUILD_DIR}/DEBIAN" >/dev/null 2>&1
  mkdir -p "${RELEASE_DIR}" >/dev/null 2>&1
}

function copy_files() {
  echo "Copy files to build dir..."
  local line=""
  local src=""
  local dest=""
  local errors=0
  if [[ -n "$CFG_FILES_CONF" ]]; then
    while IFS= read -r line; do
      [[ -z "$line" ]] && continue
      src="${line%%=*}"
      dest="${line#*=}"
      mkdir -p "$(dirname "${BUILD_DIR}${dest}")" >/dev/null 2>&1
      rm -rf "${BUILD_DIR}${dest}" >/dev/null 2>&1
      rm -f "${BUILD_DIR}${dest}" >/dev/null 2>&1
      cp -af "${src}" "${BUILD_DIR}${dest}" >/dev/null 2>&1
    done <<< "$CFG_FILES_CONF"
  fi
  if [[ -n "$CFG_DIRS_CONF" ]]; then
    while IFS= read -r line; do
      [[ -z "$line" ]] && continue
      src="${line%%=*}"
      dest="${line#*=}"
      mkdir -p "$(dirname "${BUILD_DIR}${dest}")" >/dev/null 2>&1
      rm -rf "${BUILD_DIR}${dest}" >/dev/null 2>&1
      rm -f "${BUILD_DIR}${dest}" >/dev/null 2>&1
      cp -arf "${src}" "${BUILD_DIR}${dest}" >/dev/null 2>&1
    done <<< "$CFG_DIRS_CONF"
  fi
}

function pack_payloads() {
  echo "Pack file payloads..."
  local SUCCESSCODE="TRUE"
  local entry
  local test
  IFS=$'\n'
  test=($(find "${BUILD_DIR}" -mindepth 1))
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

function create_control_file() {
  echo "Create control file..."
  echo "Package: ${CFG_NAME}" > "${BUILD_DIR}/DEBIAN/control"
  echo "Version: ${CFG_VERSION}" >> "${BUILD_DIR}/DEBIAN/control"
  echo "Priority: ${CFG_PRIORITY}" >> "${BUILD_DIR}/DEBIAN/control"
  echo "Architecture: ${CFG_ARCH}" >> "${BUILD_DIR}/DEBIAN/control"
  echo "Maintainer: ${CFG_MAINTAINER}" >> "${BUILD_DIR}/DEBIAN/control"
  echo "Description: ${CFG_DESCRIPTION}" >> "${BUILD_DIR}/DEBIAN/control"
  [ "${CFG_HOMEPAGE}" != "" ] && echo "Homepage: ${CFG_HOMEPAGE}" >> "${BUILD_DIR}/DEBIAN/control"
  [ "${CFG_DEPENDS}" != "" ] && echo "Depends: ${CFG_DEPENDS}" >> "${BUILD_DIR}/DEBIAN/control"
  [ "${CFG_CONFLICTS}" != "" ] && echo "Conflicts: ${CFG_CONFLICTS}" >> "${BUILD_DIR}/DEBIAN/control"
  [ "${CFG_SIZE}" == "" ] && CFG_SIZE="$(du -sk --exclude=DEBIAN ${BUILD_DIR} | awk '{print $1}')"
  [ "${CFG_ADD_SIZE}" != "" ] && CFG_SIZE=$((CFG_SIZE + CFG_ADD_SIZE))
  [ "${CFG_SIZE}" != "" ] && echo "Installed-Size: ${CFG_SIZE}" >> "${BUILD_DIR}/DEBIAN/control"
}

function create_scripts() {
  echo "Create control scripts..."
  local preinst_filename="preinst"
  if [[ -n "$CFG_RES_RAS_PI" ]] || [[ -n "$CFG_RES_RAS_OS" ]] || \
     [[ -n "$CFG_RES_CPU_ARCH" ]] || [[ -n "$CFG_RES_OS_ARCH" ]]; then
    cat <<EOF | sudo tee "${BUILD_DIR}/DEBIAN/$preinst_filename" >/dev/null 2>&1
#!/bin/bash
raspi="$CFG_RES_RAS_PI"
rasos="$CFG_RES_RAS_OS"
cpuarch="$CFG_RES_CPU_ARCH"
bsarch="$CFG_RES_OS_ARCH"
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
  [[ "\$rasos_v" =~ "Raspbian" ]] && [[ "\$rasos_v" =~ "trixie" ]] && [[ "\$rasos" =~ "trixie" ]] && rasos_res="true"
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
    preinst_filename="preinst_user"
  fi
  if [ "$CFG_PREINST" != "" ]; then
    if [[ -f "$CFG_PREINST" ]]; then
      cp -f "$CFG_PREINST" "${BUILD_DIR}/DEBIAN/$preinst_filename"
    else
      echo "$CFG_PREINST" > "${BUILD_DIR}/DEBIAN/$preinst_filename"
    fi
  fi
  if [ "$CFG_POSTINST" != "" ]; then
    if [[ -f "$CFG_POSTINST" ]]; then
      cp -f "$CFG_POSTINST" "${BUILD_DIR}/DEBIAN/postinst"
    else
      echo "$CFG_POSTINST" > "${BUILD_DIR}/DEBIAN/postinst"
    fi
  fi
  if [ "$CFG_PRERM" != "" ]; then
    if [[ -f "$CFG_PRERM" ]]; then
      cp -f "$CFG_PRERM" "${BUILD_DIR}/DEBIAN/prerm"
    else
      echo "$CFG_PRERM" > "${BUILD_DIR}/DEBIAN/prerm"
    fi
  fi
  if [ "$CFG_POSTRM" != "" ]; then
    if [[ -f "$CFG_POSTRM" ]]; then
      cp -f "$CFG_POSTRM" "${BUILD_DIR}/DEBIAN/postrm"
    else
      echo "$CFG_POSTRM" > "${BUILD_DIR}/DEBIAN/postrm"
    fi
  fi
}

function create_changelog() {
  local distribution="${1:-stable}"
  local urgency="${2:-low}"
  local version=""
  local date=""
  local changes=""
  local date_debian=""
  local prefix=""
  local entry=""
  local item=""
  local line=""
  local entries=()
  if [[ -n "$CFG_CHANGELOG_FILE_PATH" ]]; then
    echo "Create changelog from markdown file..."
    exec 3< <(sed 's/\r$//' "$CFG_CHANGELOG_FILE_PATH")
    while IFS= read -r line <&3 || [[ -n "$line" ]]; do
      line="$(echo "$line" | xargs)"
      if [[ "$line" =~ ^##\ \[(.+)\]\ \-\ ([0-9]{4}-[0-9]{2}-[0-9]{2}) ]]; then
        if [[ -n "$version" ]]; then
          entry="$CFG_NAME ($version) $distribution; urgency=$urgency"$'\n\n'"$changes"$'\n'" -- $CFG_MAINTAINER  $date_debian"$'\n'
          entries+=("$entry")
        fi
        version="${BASH_REMATCH[1]}"
        date="${BASH_REMATCH[2]}"
        changes=""
        prefix=""
        date_debian="$(date -d "$date" "+%a, %d %b %Y %H:%M:%S %z")"
      elif [[ "$line" =~ ^###\ (.+) ]]; then
        prefix="${BASH_REMATCH[1]}"
      elif [[ "$line" =~ ^-\ (.+) ]]; then
        item="${BASH_REMATCH[1]}"
        item="$(echo "$item" | xargs)"
        [[ -z "$item" ]] && continue
        if [[ -n "$prefix" ]]; then
          changes+="  * $prefix: $item"$'\n'
        else
          changes+="  * $item"$'\n'
        fi
      fi
    done
    if [[ -n "$version" ]]; then
      entry="$CFG_NAME ($version) $distribution; urgency=$urgency"$'\n\n'"$changes"$'\n'" -- $CFG_MAINTAINER  $date_debian"$'\n'
      entries+=("$entry")
    fi
    echo "" > "${BUILD_DIR}/DEBIAN/changelog"
    for idx in "${!entries[@]}"; do
      echo "${entries[idx]}" >> "${BUILD_DIR}/DEBIAN/changelog"
      echo "" >> "${BUILD_DIR}/DEBIAN/changelog"
    done
  elif [[ -n "$CFG_CHANGELOG_STRING" ]]; then
    echo "Create changelog from conf string..."
    echo "$CFG_CHANGELOG_STRING" > "${BUILD_DIR}/DEBIAN/changelog"
  fi
}

function create_copyright() {
  if [[ -n "$CFG_COPYRIGHT_FILE_PATH" ]]; then
    echo "Create copyright from license file..."
    local license_path="/usr/share/common-licenses"
    local license_id="Custom"
    local license_notice=""
    if grep -Eqi "GNU GENERAL PUBLIC LICENSE" "$CFG_COPYRIGHT_FILE_PATH"; then
      if grep -Eq "Version 3" "$CFG_COPYRIGHT_FILE_PATH"; then
        license_id="GPL-3"
        [[ -f "$license_path/$license_id" ]] && license_notice=" On Debian systems, the complete text of the GNU General Public License\n version 3 can be found in \"$license_path/GPL-3\"." || license_id="Custom"
      elif grep -Eq "Version 2" "$CFG_COPYRIGHT_FILE_PATH"; then
        license_id="GPL-2"
        [[ -f "$license_path/$license_id" ]] && license_notice=" On Debian systems, the complete text of the GNU General Public License\n version 2 can be found in \"$license_path/GPL-2\"." || license_id="Custom"
      fi
    elif grep -Eqi "GNU LESSER GENERAL PUBLIC LICENSE" "$CFG_COPYRIGHT_FILE_PATH"; then
      if grep -Eq "Version 3" "$CFG_COPYRIGHT_FILE_PATH"; then
        license_id="LGPL-3"
        [[ -f "$license_path/$license_id" ]] && license_notice=" On Debian systems, the complete text of the GNU Lesser General Public License\n version 3 can be found in \"$license_path/LGPL-3\"." || license_id="Custom"
      elif grep -Eq "Version 2.1" "$CFG_COPYRIGHT_FILE_PATH"; then
        license_id="LGPL-2.1"
        [[ -f "$license_path/$license_id" ]] && license_notice=" On Debian systems, the complete text of the GNU Lesser General Public License\n version 2.1 can be found in \"$license_path/LGPL-2.1\"." || license_id="Custom"
      fi
    elif grep -Eqi "Affero General Public License" "$CFG_COPYRIGHT_FILE_PATH"; then
      license_id="AGPL-3"
      [[ -f "$license_path/$license_id" ]] && license_notice=" On Debian systems, the complete text of the GNU Affero General Public License\n version 3 can be found in \"$license_path/AGPL-3\"." || license_id="Custom"
    elif grep -Eqi "MIT License" "$CFG_COPYRIGHT_FILE_PATH"; then
      license_id="MIT"
      [[ -f "$license_path/$license_id" ]] && license_notice=" On Debian systems, the complete text of the MIT License can be found in \"$license_path/MIT\"." || license_id="Custom"
    elif grep -Eqi "Apache License" "$CFG_COPYRIGHT_FILE_PATH"; then
      license_id="Apache-2.0"
      [[ -f "$license_path/$license_id" ]] && license_notice=" On Debian systems, the complete text of the Apache License 2.0 can be found in \"$license_path/Apache-2.0\"." || license_id="Custom"
    elif grep -Eqi "BSD" "$CFG_COPYRIGHT_FILE_PATH"; then
      license_id="BSD-3-Clause"
      [[ -f "$license_path/$license_id" ]] && license_notice=" On Debian systems, the complete text of the BSD 3-Clause License can be found in \"$license_path/BSD\"." || license_id="Custom"
    elif grep -Eqi "Creative Commons.*Attribution" "$CFG_COPYRIGHT_FILE_PATH"; then
      license_id="CC-BY-4.0"
      license_notice=" This project is licensed under the Creative Commons Attribution 4.0 International License.\n See: https://creativecommons.org/licenses/by/4.0/"
    fi
    {
      echo "Format: https://www.debian.org/doc/packaging-manuals/copyright-format/1.0/"
      echo "Upstream-Name: $CFG_NAME"
      echo "Upstream-Contact: $CFG_MAINTAINER"
      echo ""
      echo "Files: *"
      echo "Copyright: $(date +%Y) ${CFG_MAINTAINER%%<*}"
      echo "License: $license_id"
      echo ""
      if [[ "$license_id" == "Custom" ]]; then
        sed 's/\r$//' "$CFG_COPYRIGHT_FILE_PATH" | sed 's/^/ /'
      else
        echo -e "$license_notice"
      fi
    } > "${BUILD_DIR}/DEBIAN/copyright"

  elif [[ -n "$CFG_COPYRIGHT_STRING" ]]; then
    echo "Create copyright from conf string..."
    {
      echo "Format: https://www.debian.org/doc/packaging-manuals/copyright-format/1.0/"
      echo "Upstream-Name: $CFG_NAME"
      echo "Upstream-Contact: $CFG_MAINTAINER"
      echo ""
      echo "Files: *"
      echo "Copyright: $(date +%Y) ${CFG_MAINTAINER%%<*}"
      echo "License: Custom"
      echo ""
      echo "$CFG_COPYRIGHT_STRING" | sed 's/^/ /'
    } > "${BUILD_DIR}/DEBIAN/copyright"
  fi
}

function set_package_file_perms() {
  echo "Set package-files perms..."
  local filetype
  local entry
  local test
  IFS=$'\n'
  test=($(find "${BUILD_DIR}"))
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

function build_deb() {
  echo "Build deb package..."
  local SUCCESSCODE="TRUE"
  rm -f "${RELEASE_DIR}/${DEB_BASE_FILE_NAME}.deb"
  dpkg-deb -Zxz --build "${BUILD_DIR}" "${RELEASE_DIR}/${DEB_BASE_FILE_NAME}.deb" >/dev/null 2>&1
  if [ $? -ne 0 ]; then
    set_final_file_perms
    echo "build deb package error! abort."
    SUCCESSCODE="FALSE"
  fi
  [ "${SUCCESSCODE}" != "TRUE" ] && return 1 || return 0
}

function set_final_file_perms() {
  chown -Rf ${USERID}:${GROUPID} "${BUILD_DIR}" >/dev/null 2>&1
  chown -Rf ${USERID}:${GROUPID} "${RELEASE_DIR}" >/dev/null 2>&1
}

function cmd_start_building() {
  cd "${SCRIPT_DIR}"
  [ -n "$CMD" ] && CONFIG_FILE="$CMD"
  check_commands || return 1
  config_read_check_file || return 1
  clean_build_dir
  copy_files
  pack_payloads || return 1
  create_control_file
  create_scripts
  create_changelog
  create_copyright
  set_package_file_perms
  build_deb || return 1
  set_final_file_perms
}

function cmd_print_version() {
  echo "$SCRIPT_TITLE v$SCRIPT_VERSION"
}

function cmd_print_help() {
  echo "Usage: $(basename ""$0"") [OPTION]"
  echo "$SCRIPT_TITLE v$SCRIPT_VERSION"
  echo "Configuarable Debian Package file builder"
  echo " "
  echo "[config_path]           path to config file"
  echo "-t, --test              creates test deb package (no commit)"
  echo "-v, --version           print version info and exit"
  echo "-h, --help              print this help and exit"
  echo " "
  echo "Only one option at same time is allowed!"
  echo " "
  echo "Author: aragon25 <aragon25.01@web.de>"
}

if [ "$CMD" != "version" ] && [ "$CMD" != "help" ]; then
  cmd_start_building
  EXITCODE=$?
elif [[ "$CMD" == "version" ]]; then
  cmd_print_version
elif [[ "$CMD" == "help" ]]; then
  cmd_print_help
fi

exit $EXITCODE
