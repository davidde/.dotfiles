# Setup for using GPG keys as SSH key.
# This assumes that the keygrip of the GPG 'Authenticate' subkey
# is listed in the sshcontrol file at `~/.gnupg/sshcontrol`,
# and `enable-ssh-support` is added to `~/.gnupg/gpg-agent.conf`.

# Make sure SSH agent is not used, so we can use GPG agent:
unset SSH_AGENT_PID

# When gpg-agent is started as `gpg-agent --daemon /bin/sh` the shell
# inherits the SSH_AUTH_SOCK variable from its parent gpg-agent process,
# and should not be set here:
if [ "${gnupg_SSH_AUTH_SOCK_by:-0}" -ne $$ ]; then
  # Setting SSH_AUTH_SOCK will make SSH use gpg-agent instead of ssh-agent:
  export SSH_AUTH_SOCK="$(gpgconf --list-dirs agent-ssh-socket)"
fi

# Configure pinentry to use the correct TTY by setting GPG_TTY:
export GPG_TTY=$(tty)
# Refresh the TTY in case the user switched into an X session:
gpg-connect-agent updatestartuptty /bye >/dev/null



