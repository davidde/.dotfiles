# Aliases
#############

# System

# For large transfers over slow networks, add the -z/--compress flag to rsync.
alias cpr='rsync -ha --info=progress2 --exclude={".Trash*",lost+found,.DS_Store,"._*"}'
# The `--delete` flag makes sure that files that no longer exist
# in the source location are also removed in the destination.
# (Very useful for maintaining exact duplicates with incremental updates.
# However; be careful with the trailing slash syntax for the source location,
# as this could potentially be very bad when combined with the wrong destination.)
alias cprd='rsync -ha --delete --info=progress2 --exclude={".Trash*",lost+found,.DS_Store,"._*"}'
# Another option is unison, which is built specifically for 2 way sync,
# and will be much faster at diffing large directories since it stores
# the diffs locally in `~/.unison`:
alias cpu='unison -auto'  # Usage: `unison /src /dest`
alias cpufat='unison -auto -fat' # To prevent errors when copying to fat/exfat file systems!
# Note that unison will by default also propagate changes in /dest back to /src,
# since it is a 2 way sync tool. If this is not desired,
# specify `-force /path/to/src-or-dest`, which effectively results in a 1 way sync
# by prioritising src or dest. Aliases for convencience:
alias cpufs='unison_force src'
alias cpufd='unison_force dest'
alias cpv='cp -vir'
alias mvv='mv -vi'
alias rmv='rm -vir'
alias ll='ls --group-directories-first -halv'
alias md='mkdir -vp'
alias grp='grep -Irni'

# Custom

alias bs='btrfs_snapshot'

alias calibu='calibre_backup /storage/backup/backup/calibre'

alias difstr='diff_string'
alias dot='~/.dotfiles/submodules/dotcon/dotcon/dotcon.py'
alias dotfiles='code -n ~/.dotfiles'

alias ffcv=' ffmpeg_convert.zsh'
alias fnd='find_file'
# Find which processes are using a device;
# useful for finding the cause of a 'busy' device that won't unmount.
# Usage:  sudo fuser -vm /dev/sdb
alias fu='sudo fuser -vm'

alias ghostscript='/usr/bin/gs' # gs aliased to `git status`
# The ${=} syntax is a fix for when editors are defined with flags:
alias gitconf='${=EDITOR} ~/.gitconfig'
alias hiber='sudo systemctl hibernate'

alias ka='killall -9'
alias kl='kill -9'

alias lock=' luks_lock.zsh'
alias unlock=' luks_unlock.zsh'

alias mpt=' mpv_tube'

alias omzdir='code -nw ~/.oh-my-zsh && . ~/.zshrc'

alias pacdep='pacman_query_info "Depends On"'
alias pacreq='pacman_query_info "Required By"'

# See Zsh function source file LOCATION, alias definition, or binary paths:
alias see='whence -v' # More complete "which" command
alias session='echo $XDG_SESSION_TYPE'
# Make sudo work with aliases:
alias s='sudo ' # This allows e.g. `s ll /root`;
# whereas `sudo ll /root` would return `sudo: ll: command not found`

# Enter a root shell with zsh and normal dotfiles, instead of default bash:
alias suz='sudo --preserve-env --shell $(which zsh)'

alias ts='echo $(timestamp)'

alias vsconf='code -n ~/.config/Code/User/settings.json'
alias vsn='code -n'
alias vsw='code -nw'
# -n, --new-window: Force VScode to open in new window
# -w, --wait: Wait for the files to be closed before returning
  
# Get complete website for offline viewing/inspection:
alias wgetall=' wget --recursive --no-parent --page-requisites --convert-links \
                     --adjust-extension --user-agent=Mozilla -e robots=off'
alias yt=' youtube-dl'
alias yta=' youtube-dl --extract-audio --audio-format mp3 --audio-quality 0'

alias zhist='${=EDITOR} ~/.zsh_history'
alias zshrc='${=EDITOR} ~/.zshrc'
alias zshre='. ~/.zshrc'


# Functions
###############

# Create btrfs snapshots for `/` and `/home`:
function btrfs_snapshot() {
  local timing=$(timestamp)
  sudo btrfs subvolume snapshot / /snapshots/${timing}-@
  sudo btrfs subvolume snapshot /home /snapshots/${timing}-@home
}

# Burn an iso file to an USB disk:
# (Use `lsblk` to find the correct disk path; e.g. /dev/sdb)
function burn() {
  if [[ $# -ne 2 ]]; then
    echo "Usage: burn <path/to/iso/file> <path/to/usb/disk>"
    return 1
  else
    sudo dd bs=4M if=$1 of=$2 status=progress oflag=sync
  fi
}

# Backup all calibre libraries to the specified directory:
function calibre_backup() {
  if [[ $# -ne 1 ]]; then
    echo "Usage: calibre_backup <path/to/backup/dir>"
    echo "       (Do not use a trailing slash.)"
    return 1
  else
    calibre-debug --export-all-calibre-data $1/$(timestamp)-calibre-all all
  fi
}

# Call the diff tool with strings instead of files:
# (Requires https://github.com/ymattw/ydiff: pip install ydiff)
function diff_string() {
  if [[ $# -ne 2 ]]; then
    echo "Usage: diff_string <string1> <string2>"
    return 1
  else
    local result=$(diff -u <(echo $1) <(echo $2))
    if [[ -z $result ]]; then
      echo "Exactly the same"
    else
      echo $result | ydiff
    fi
  fi
}

# Convert doc/docx to pdf:
function topdf() {
  if [[ $# -ne 1 ]]; then
    echo "Usage: topdf <path/to/doc/file>"
    return 1
  else
    # Install lowriter with: `sudo pacman -Syu unoconv`
    lowriter --convert-to pdf --outdir $(dirname $1) $1
  fi
}

# Find a file in directory (defaults to current directory):
function find_file {
  if [[ -z $1 ]]; then
    echo 'Usage:  find_file <file/pattern> [<search_path>]\n'
    echo '        search_path defaults to current directory.'
    echo '        Quoting (or escaping, e.g. \* for glob) is required when specifying a pattern.'
    return 1
  fi
  find ${2:-.} -type f -name $1
}

# Stream an URL in MPV without downloading:
function mpv_tube() {
  if [[ $# -ne 1 ]]; then
    echo "Stream an URL in MPV without downloading.\n"
    echo "Usage: mpv_tube <URL>"
    return 1
  else
    youtube-dl -o - $1 | mpv -
  fi
}

# Query a subfield of `pacman -Qi`:
function pacman_query_info() {
  if [[ $# -ne 2 ]]; then
    echo "Query a subfield of `pacman -Qi`.\n"
    echo "Usage: pacman_query_info <subfield> <package>"
    return 1
  else
    pacman -Qi $2 | grep $1
  fi
}

# 1-way sync with unison by forcing the state of one replica over the other:
function unison_force() {
  if [[ $# -lt 3 ]]; then
    echo "Usage: unison_force <src/dest> </path/to/src> </path/to/dest> [<options>]"
    echo "       The first argument indicates which changes should take precedence."
    return 1
  else
    local force_replica=$1
    local src=$2
    local dest=$3
    argv[1,3]=() # Remove first 3 arguments from argv list

    if [[ $force_replica == 'src' ]]; then
      unison -auto $src $dest -force $src $@
    elif [[ $force_replica == 'dest' ]]; then
      unison -auto $src $dest -force $dest $@
    else
      echo "First argument should be either 'src' or 'dest'."
      return 1
    fi
  fi
}