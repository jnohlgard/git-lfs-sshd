#!/bin/sh
set -eu
set -o pipefail

[ "${DEBUG:-}" = 'true' ] && set -x

if [ $# -ge 1 ]; then
  case "$1" in
    /usr/sbin/sshd | /sbin/sshd | sshd)
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

printf '> Starting OpenSSH server for git repo hosting\n\n'
printf 'Command: '
printf " '%s'" "$@"
printf '\n'

authorized_keys_dir=/srv/git/authorized_keys

# Generate host keys and move to subdir to make it easier to use a volume for keys
if ! ls /etc/ssh/keys/ssh_host_*_key &>/dev/null; then
  ssh-keygen -A
  mkdir -p /etc/ssh/keys
  mv /etc/ssh/ssh_host_*_key /etc/ssh/ssh_host_*_key.pub /etc/ssh/keys/
  chmod 0600 /etc/ssh/keys/ssh_host_*_key
  chmod 0644 /etc/ssh/keys/ssh_host_*_key.pub
fi

printf '>>> SSH server host key fingerprints:\n'
for keyfile in /etc/ssh/keys/ssh_host_*_key; do
  ssh-keygen -lf "${keyfile}"
done

user_owned_authorized_keys_files=$(find "${authorized_keys_dir}" -maxdepth 1 -type f -name '*.pub' -user 'git' -print)
if [ -n "${user_owned_authorized_keys_files}" ]; then
  >&2 printf 'WARNING: Found authorized_keys files owned by user "git":\n'
  >&2 printf '%s\n' "${user_owned_authorized_keys_files}"
fi

# Warn if no authorized_keys
if ! ls "${authorized_keys_dir}"/*.pub &>/dev/null; then
  >&2 printf 'WARNING: no <key>.pub files in %s!\n' "${authorized_keys_dir}"
fi

exec "$@"
