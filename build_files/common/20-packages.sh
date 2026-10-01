#!/bin/bash
# Packages and services shared by every variant

set -ouex pipefail

dnf5 install -y tmux vim tree

# Enable Podman socket
systemctl enable podman.socket

# Disable annoying motd service
systemctl disable coreos-container-signing-migration-motd.service
