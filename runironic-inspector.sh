#!/usr/bin/bash

CONFIG=/etc/ironic-inspector/inspector.conf

. /bin/ironic-common.sh

wait_for_interface_or_ip

# Allow access to Ironic inspector API
if ! iptables -C INPUT -i "$PROVISIONING_INTERFACE" -p tcp -m tcp --dport 5050 -j ACCEPT > /dev/null 2>&1; then
    iptables -I INPUT -i "$PROVISIONING_INTERFACE" -p tcp -m tcp --dport 5050 -j ACCEPT
fi

# Allow access to mDNS
if ! iptables -C INPUT -i $PROVISIONING_INTERFACE -p udp --dport 5353 -j ACCEPT > /dev/null 2>&1; then
    iptables -I INPUT -i $PROVISIONING_INTERFACE -p udp --dport 5353 -j ACCEPT
fi
if ! iptables -C OUTPUT -p udp --dport 5353 -j ACCEPT > /dev/null 2>&1; then
    iptables -I OUTPUT -p udp --dport 5353 -j ACCEPT
fi

# Remove log files from last deployment
rm -rf /shared/log/ironic-inspector

mkdir -p /shared/log/ironic-inspector

cp $CONFIG $CONFIG.orig

crudini --set $CONFIG ironic endpoint_override http://$IRONIC_URL_HOST:6385
crudini --set $CONFIG service_catalog endpoint_override http://$IRONIC_URL_HOST:5050
crudini --set $CONFIG mdns interfaces $PROVISIONING_IP

exec /usr/bin/ironic-inspector --config-file /etc/ironic-inspector/inspector-dist.conf \
	--config-file /etc/ironic-inspector/inspector.conf \
	--log-file /shared/log/ironic-inspector/ironic-inspector.log
