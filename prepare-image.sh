 #!/usr/bin/bash

set -euxo pipefail

dnf upgrade -y
dnf --setopt=install_weak_deps=False install -y $(cat /tmp/${PKGS_LIST})
if [[ ! -z ${EXTRA_PKGS_LIST:-} ]]; then
    if [[ -s /tmp/${EXTRA_PKGS_LIST} ]]; then
        dnf --setopt=install_weak_deps=False install -y $(cat /tmp/${EXTRA_PKGS_LIST})
    fi
fi
mkdir -p /var/lib/ironic-inspector
sqlite3 /var/lib/ironic-inspector/ironic-inspector.db "pragma journal_mode=wal"
dnf remove -y sqlite
dnf clean all
rm -rf /var/cache/{yum,dnf}/*
