#!/usr/bin/env bash

TRUE=0
FALSE=1
# Clear stdin.
function _ui_clear_stdin() {
  local dummy
  read -r -t 1 -n 100000 dummy
}
function _backtrace() {
  echo "backtrace is:"
  i=0
  while caller ${i}
  do
    i=$((i+1))
  done
}

function assert_fail() {
  # Print assert errors to stderr!
  echo "assert failed: \"$@\"" >&2
  _backtrace >&2

  # And crash immediately.
  kill -s USR1 ${TOP_PID}
}

function assert() {
  if [ $# -ne 1 ]
  then  
    assert_fail "assert called with wrong number of parameters!"
  fi

  if [ ! $1 ]
  then
    assert_fail $1
  fi
}

function assert_range() {
  if [ $# -ne 3 ]
  then
    assert_fail "assert_range called with wrong number of parameters!"
  fi

  assert "${1} -ge ${2} -a ${1} -le ${3}"
}
# Ask the user a yes/no question.
# Returns ${TRUE} for yes, ${FALSE} for no.
# If the user aborts the question by hitting
# Ctrl+D, the return value defaults to no/${FALSE},
# unless otherwise specified in the second parameter.
function ask() {
  assert "$# -ge 1"

  _ui_clear_stdin

  local message=$1
  if [ $# -gt 1 ]; then
    local default=$2
  else
    local default=${FALSE}
  fi

  echo ${message}
  select yn in "Yes" "No"; do
    case ${yn} in
      "Yes")
        return ${TRUE}
        ;;
      "No")
        return ${FALSE}
        ;;
    esac
  done

  # Ctrl-D pressed.
  return ${default}
}
# Let the user enter a variable.
# Optionally specify a default value.
function enter_variable() {
  assert_range $# 1 2

  _ui_clear_stdin

  local message=$1
  local var=""

  if [ $# -eq 2 ]; then
    local default=$2

    read -p "${message} [${default}] >> " var

    if [ -z ${var} ]; then
      var=${default}
    fi
  else
    read -p "${message} >> " var
  fi

  echo ${var}
}
# Let the user enter a hidden variable (e.g., password).
function enter_variable_hidden() {
  assert_eq $# 1

  _ui_clear_stdin

  local message=$1
  local var=""

  read -s -p "${message} >> " var
  echo >&2 # Print the newline to stdout explicitly, since read -s gobbles it away.
  echo ${var}
}

## Move and apply the custom configuration
mv alis.conf alis.conf.bak
awk -F= '!a[$1]++' alis_custom.conf alis.conf.bak > alis.conf
mv alis-packages.conf alis-packages.conf.bak
awk -F= '!a[$1]++' alis_packages_custom.conf alis-packages.conf.bak > alis-packages.conf

optional_firmware="mkinitcpio-firmware"

if ask "Custom mirror?"; then
  mirror=$(enter_variable " - Custom mirror")
  sed -i "s/PACMAN_MIRROR=\".*\"/PACMAN_MIRROR=\"$mirror\"/g" ./alis.conf
fi

if ask "Optional firmware?"; then
  sed -i "s/PACKAGES_AUR_CUSTOM=\"\(.*\)\"/PACKAGES_AUR_CUSTOM=\"$optional_firmware \1\"/g" ./alis-packages.conf
fi


# Hostname
hostname=$(enter_variable " - Hostname?", $HOSTNAME)
sed -i "s/^HOSTNAME=\".*\"/HOSTNAME=\"$hostname\"/g" ./alis.conf

# Username
username=$(enter_variable " - Username", $USER_NAME)
sed -i "s/USER_NAME=\".*\"/USER_NAME=\"$username\"/g" ./alis.conf
