#!/bin/zsh

# Script to unmount and lock LUKS encrypted devices by name alone.
# Will prompt for sudo access.


# Prepend a string to the output of a command:
# E.g.: cmd | prepend "[ERROR] "
function prepend() {
  while read line; do
    echo "${1}${line}"
  done
}


if [[ $# -ne 1 ]]; then
  echo "Usage: lock <mapper-name>\n"
  echo "Requires up-to-date crypttab and fstab."
  return 1 # Incorrect arg number
fi

sudo umount -v /dev/mapper/$1
# 'umount' will fail on an already unmounted volume,
# so we check the mount status with grep:
if grep -qs "/dev/mapper/$1 " /proc/mounts; then
  print -P "\n%B%F{red}Failed unmounting '$1'.%b%f"
  return 3 # Mount failure
fi

sudo cryptsetup -v close $1 | prepend "luksClose: "
if [[ ${pipestatus[1]} -eq 0 ]]; then
  print -P "\n%B%F{green}Unmounted and LOCKED '$1'.%b%f"
else
  print -P "\n%B%F{red}Failed locking LUKS volume '$1'.%b%f"
  return 2 # Lock failure
fi

