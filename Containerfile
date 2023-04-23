ARG alpine_version
FROM docker.io/golang:alpine${alpine_version:-} as builder

RUN go install github.com/charmbracelet/git-lfs-transfer@latest

FROM alpine:${alpine_version:-latest}

ARG git_root=/srv/git

RUN apk add --no-cache openssh-server git && \
    mkdir -p "${git_root}/authorized_keys" "${git_root}/repos" "${git_root}/git-shell-commands" && \
    addgroup -S git && \
    adduser -S -G git -s /usr/bin/git-shell -D -h "${git_root}" -H git && \
    printf '%s\n' 'git:*' | chpasswd -e && \
    addgroup -S authorized-keys && \
    adduser -S -G authorized-keys -s /bin/false -D -h "${git_root}" -H authorized-keys && \
    chown git:git "${git_root}/repos"

COPY files/entry.sh /entry.sh
COPY files/repo-access /usr/local/bin/
COPY files/repo-access-keys /usr/local/bin/
COPY files/sshd_config /etc/ssh/sshd_config
COPY files/git-shell-commands/* ${git_root}/git-shell-commands/

COPY --from=builder /go/bin/git-lfs-transfer  /usr/local/bin/git-lfs-transfer

ENTRYPOINT ["/entry.sh"]

CMD ["/usr/sbin/sshd", "-D", "-e", "-f", "/etc/ssh/sshd_config"]
EXPOSE 22
