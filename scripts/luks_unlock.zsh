#!/bin/zsh

# Script to unlock and mount LUKS encrypted devices by name alone.
# Will prompt for sudo access.
#
# Notes:
# * This assumes a fully up-to-date crypttab and fstab, e.g.:
#     fstab:    UUID=<mapper-UUID>  /storage/MAIN  ext4  defaults,noatime  0  2
#     crypttab: MAIN  UUID=<physical-UUID>  /root/.keyfile  luks
#   Specifying 'noauto' instead of 'luks' will prevent auto-mounting on boot,
#   and prevent apps like Gnome Disks from mounting it without further credentials.
#   This way, sudo access is required for anyone wanting to unlock it.
#   (Note this requires setting the fsck field (last field of fstab) to 0 !)
# * Both the key file and device UUID are extracted from the crypttab,
#   in order to make it possible to only have to specify the device name
#   (first field of crypttab). The key file is used by default to unlock,
#   because this is both more secure as well as practical;
#   this way you can use a really long passphrase, without having to enter it manually.
# * I am aware of `systemd-cryptsetup@name` for unlocking
#   luks containers by their name alone, but these systemd services
#   seem to be buggy, inconsistent and have horrible documentation.
#   E.g.: Running `sudo systemctl stop systemd-cryptsetup@VOLUME` may or may not
#         successfully "luksClose" the volume, but in neither case will it notify you
#         of success or failure ...


# Prepend a string to the output of a command:
# E.g.: cmd | prepend "[ERROR] "
function prepend() {
  while read line; do
    echo "${1}${line}"
  done
}


if [[ $# -ne 1 ]]; then
  echo "Usage: unlock <mapper-name>\n"
  echo "Requires up-to-date crypttab and fstab."
  echo "Will use key file '$LUKS_KEYFILE', but prompt for password if incorrect."
  return 1 # Incorrect arg number
fi

local UUID=$(sudo grep -oP "^$1\s+UUID=\K[^ ]*" /etc/crypttab)
# -o, --only-matching: return only the matched part
# -P, --perl-regexp: interpret as Perl regex
# \K: Perl regex that causes the string matched so far to be dropped
if [[ -z $UUID ]]; then
  echo "UUID of '$1' not found in crypttab:"
  echo "* Add the following entry to '/etc/crypttab' to make this work:"
  echo "  $1 UUID=<UUID-of-physical-device> /path/to/keyfile noauto"
  echo "* Or enter the device name interactively:"
  echo -n "  /dev/"
  read device
  echo ""
else
  local device="disk/by-uuid/$UUID"
fi

local LUKS_KEYFILE=$(sudo grep -oP "^$1\s+UUID=\S+\s+\K[^ ]*" /etc/crypttab)
if [[ -z $LUKS_KEYFILE || $LUKS_KEYFILE != /* ]]; then # no keyfile path, e.g. none
  # Try opening with passphrase instead of keyfile:
  sudo cryptsetup -v open /dev/$device $1 | head -n 1
  local exitcode="${pipestatus[1]}" # 1 is first element of pipeline!
else
  sudo cryptsetup -v open /dev/$device $1 --key-file=$LUKS_KEYFILE | prepend "luksOpen: " | head -n 1
  local exitcode="${pipestatus[1]}" # 1 is first element of pipeline!
fi

if [[ $exitcode -ne 0 && $exitcode -ne 5 ]]; then
# 5: device already exists or is busy (i.e. already unlocked)
  print -P "\n%B%F{red}Failed unlocking LUKS volume '$1'.%b%f"
  return 2 # Lock failure
fi

sudo mount -v /dev/mapper/$1
if grep -qs "/dev/mapper/$1 " /proc/mounts; then
  print -P "\n%B%F{green}UNLOCKED and mounted '$1'.%b%f"
else
  print -P "\n%B%F{red}Mounting FAILED!%b%f"
  return 3 # Mount failure
fi

