#!/bin/bash

set -ouex pipefail

### Copy static files (systemd units, configs) into the image
cp -a /ctx/system_files/. /
install -d -m 0700 /etc/materia

### Install packages
dnf5 install -y tmux targetcli vim tree

# Enable Podman socket
systemctl enable podman.socket

# Get iSCSI services running at boot
systemctl enable iscsid
systemctl enable target

# Disable annoying motd service
systemctl disable coreos-container-signing-migration-motd.service

# Set up Materia
# renovate: datasource=github-releases depName=stryan/materia
MATERIA_VERSION=v0.7.2
case "$(uname -m)" in
  x86_64)  MATERIA_ARCH=amd64; MATERIA_SHA256=5d039e1b0727fda93167b68aafd038220c06acd61820d267641e964f4d614da0 ;;
  aarch64) MATERIA_ARCH=arm64; MATERIA_SHA256=19192e31c9a4825bf4ef5224dea076f3a47ffbbe919c667e8a7150b16936b841 ;;
  *) echo "Unsupported architecture: $(uname -m)" >&2; exit 1 ;;
esac

curl -fsSL -o /usr/bin/materia \
  "https://github.com/stryan/materia/releases/download/${MATERIA_VERSION}/materia-${MATERIA_ARCH}"
echo "${MATERIA_SHA256}  /usr/bin/materia" | sha256sum -c -
chmod 0755 /usr/bin/materia

systemctl enable materia-update.timer
