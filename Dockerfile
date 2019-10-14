FROM golang:1.13-alpine

LABEL maintainer="Miguel Angel <miguel.a.j82@gmail.com>"

ENV GOPATH /go
ENV CGO_ENABLED 0
ENV GO111MODULE on
ENV MC_RELEASE RELEASE.2019-10-09T22-54-57Z

RUN  \
     apk add --no-cache git && \
     git clone https://github.com/minio/mc && cd mc && \
     git checkout ${MC_RELEASE} && \
     go install -v -ldflags "$(go run buildscripts/gen-ldflags.go)"

FROM alpine:latest
# Steps done in one RUN layer:
# - Install packages
# - Fix default group (1000 does not exist)
# - OpenSSH needs /var/run/sshd to run
# - Remove generic host keys, entrypoint generates unique keys
RUN echo "@community http://dl-cdn.alpinelinux.org/alpine/edge/community" >> /etc/apk/repositories && \
    apk add --no-cache bash shadow@community openssh openssh-sftp-server && \
    sed -i 's/GROUP=1000/GROUP=100/' /etc/default/useradd && \
    mkdir -p /var/run/sshd && \
    rm -f /etc/ssh/ssh_host_*key*

COPY files/sshd_config /etc/ssh/sshd_config
COPY files/create-sftp-user /usr/local/bin/
COPY --from=0 /go/bin/mc /usr/local/bin/
COPY files/entrypoint /

EXPOSE 22

ENTRYPOINT ["/entrypoint"]
