#!/bin/sh

set -euo pipefail

[ "${DEBUG:-}" = 'true' ] && set -x

if [ $# -ge 1 ];then
  case "$1" in
    */sshd | sshd)
      shift;;
    -*)
      ;;
    *)
      # not starting sshd when a different command is given
      exec "$@"
      ;;
  esac
fi
set -- /usr/sbin/sshd "$@"

printf '> Starting OpenSSH server\n\n'

printf 'Command: '
printf " '%s'" "$@"
printf '\n'

# Copy default config from cache, if required
if [ ! -e '/etc/ssh/sshd_config' ]; then
  printf 'Missing configuration in %s, copying default config from %s\n' /etc/ssh /etc/ssh.default/
  cp -a /etc/ssh.default/* /etc/ssh/
fi

# Generate Host keys, if required
ssh-keygen -A
chmod 0600 '/etc/ssh/sshd_host_'*'_keys'
chmod 0644 '/etc/ssh/sshd_host_'*'_keys.pub'
printf '>>> SSH server host key fingerprints:\n'
for item in '/etc/ssh/ssh_host_'*'_key'; do
  ssh-keygen -lvf "/etc/ssh/ssh_host_${item}_key"
done

# Check file permissions
if [ -w /etc/authorized_keys ]; then
  chown root:root /etc/authorized_keys
  chmod 755 /etc/authorized_keys
  for f in $(find /etc/authorized_keys/ -type f -maxdepth 1); do
    chmod 0644 "${f}"
  done
fi

# Warn if no authorized_keys
if [ ! -e /etc/authorized_keys/git ]; then
  printf 'WARNING: Missing /etc/authorized_keys/git!\n'
fi

exec "$@"
