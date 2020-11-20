 #!/usr/bin/bash

set -ex

dnf upgrade -y
dnf install -y $(cat /tmp/main-packages-list.txt)
mkdir -p /var/lib/ironic-inspector
sqlite3 /var/lib/ironic-inspector/ironic-inspector.db "pragma journal_mode=wal"
dnf remove -y sqlite
dnf clean all
rm -rf /var/cache/{yum,dnf}/*
