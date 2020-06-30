#!/usr/bin/bash

CONFIG=/etc/ironic-inspector/inspector.conf
USE_HTTP_BASIC=${USE_HTTP_BASIC:-false}
INSPECTOR_HTTP_BASIC_USERNAME=${INSPECTOR_HTTP_BASIC_USERNAME:-"change_me"}
INSPECTOR_HTTP_BASIC_PASSWORD=${INSPECTOR_HTTP_BASIC_PASSWORD:-"change_me"}
IRONIC_HTTP_BASIC_USERNAME=${IRONIC_HTTP_BASIC_USERNAME:-"change_me"}
IRONIC_HTTP_BASIC_PASSWORD=${IRONIC_HTTP_BASIC_PASSWORD:-"change_me"}

. /bin/ironic-common.sh

wait_for_interface_or_ip

cp $CONFIG $CONFIG.orig

crudini --set $CONFIG ironic endpoint_override http://$IRONIC_URL_HOST:6385
crudini --set $CONFIG service_catalog endpoint_override http://$IRONIC_URL_HOST:5050

if [ "$USE_HTTP_BASIC" = "true" ]; then
        crudini --set $CONFIG DEFAULT auth_strategy http_basic
        crudini --set $CONFIG DEFAULT http_basic_auth_user_file /shared/htpasswd-ironic-inspector
        crudini --set $CONFIG ironic auth_type http_basic
        crudini --set $CONFIG ironic username $IRONIC_HTTP_BASIC_USERNAME
        crudini --set $CONFIG ironic password $IRONIC_HTTP_BASIC_PASSWORD

        htpasswd -nbB $INSPECTOR_HTTP_BASIC_USERNAME $INSPECTOR_HTTP_BASIC_PASSWORD > /shared/htpasswd-ironic-inspector
fi

exec /usr/bin/ironic-inspector --config-file /etc/ironic-inspector/inspector-dist.conf \
	--config-file /etc/ironic-inspector/inspector.conf
