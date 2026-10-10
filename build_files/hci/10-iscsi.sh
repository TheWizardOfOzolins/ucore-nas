#!/bin/bash
# iSCSI target

set -ouex pipefail

dnf5 install -y targetcli
systemctl enable iscsid
systemctl enable target
