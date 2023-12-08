#!/usr/bin/env bash
set -e

apt-get -y install cloud-init

cat -> /etc/cloud/cloud.cfg.d/nocloud.cfg <<EOF
datasource_list: [ NoCloud, None ]
datasource:
  NoCloud:
    fs_label: None
EOF

# We're fairly certain about what the network hardware configuration is going
# to look like, so let's disable cloudinit's.
cat > /etc/cloud/cloud.cfg.d/disable-network-configuration.cfg <<EOF
network: { config: disabled }
EOF
