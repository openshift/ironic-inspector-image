#!/usr/bin/bash

CONFIG=/etc/ironic-inspector/inspector.conf

export IRONIC_INSPECTOR_ENABLE_DISCOVERY=${IRONIC_INSPECTOR_ENABLE_DISCOVERY:-false}

. /bin/ironic-common.sh

wait_for_interface_or_ip

cp $CONFIG $CONFIG.orig

crudini --set $CONFIG ironic endpoint_override http://$IRONIC_URL_HOST:6385
crudini --set $CONFIG service_catalog endpoint_override http://$IRONIC_URL_HOST:5050


# Configure HTTP basic auth for API server
HTPASSWD_FILE=/etc/ironic-inspector/htpasswd
if [ -n "${HTTP_BASIC_HTPASSWD}" ]; then
    printf "%s\n" "${HTTP_BASIC_HTPASSWD}" >"${HTPASSWD_FILE}"
    crudini --set $CONFIG DEFAULT auth_strategy http_basic
    crudini --set $CONFIG DEFAULT http_basic_auth_user_file "${HTPASSWD_FILE}"
fi

if [[ "$IRONIC_INSPECTOR_ENABLE_DISCOVERY" == "true" ]]; then
    crudini --set $CONFIG processing node_not_found_hook enroll
    crudini --set $CONFIG discovery enroll_node_driver ipmi
fi

# Configure auth for ironic client
CONFIG_OPTIONS="--config-file /etc/ironic-inspector/inspector-dist.conf --config-file ${CONFIG}"
auth_config_file="/auth/ironic/auth-config"
if [ -f ${auth_config_file} ]; then
    CONFIG_OPTIONS+=" --config-file ${auth_config_file}"
fi

exec /usr/bin/ironic-inspector $CONFIG_OPTIONS
