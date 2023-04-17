FROM docker.io/golang:alpine as builder

RUN go install github.com/charmbracelet/git-lfs-transfer@latest

FROM alpine:3.14

RUN apk add --no-cache openssh-server && \
    mkdir -p /etc/authorized_keys && \
    cp -a /etc/ssh /etc/ssh.default && \
    addgroup -S git && adduser -S -G git git && \
    mkdir -p /data

COPY --from=builder /go/bin/git-lfs-transfer /usr/local/bin/git-lfs-transfer

EXPOSE 22

COPY entry.sh /entry.sh

ENTRYPOINT ["/entry.sh"]

CMD ["/usr/sbin/sshd", "-D", "-e", "-f", "/etc/ssh/sshd_config"]
