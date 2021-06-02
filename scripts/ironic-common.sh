function get_provisioning_interface() {
  if [ -n "${PROVISIONING_INTERFACE}" ]; then
    # don't override the PROVISIONING_INTERFACE if one is provided
    echo ${PROVISIONING_INTERFACE}
    return
  fi

  mac_env_name=MAC_${NODE_NAME}
  mac=${!mac_env_name}
  if [ -n "$mac" ]; then
    export PROVISIONING_INTERFACE=$(ip -br link show up | grep "$mac" | cut -f 1 -d ' ')
  else
    export PROVISIONING_INTERFACE="provisioning"
  fi
  echo ${PROVISIONING_INTERFACE}
}

export PROVISIONING_INTERFACE=$(get_provisioning_interface)

# Wait for the interface or IP to be up, sets $IRONIC_IP
function get_ironic_ip() {
  # If $PROVISIONING_IP is specified, then we wait for that to become available on an interface, otherwise we look at $PROVISIONING_INTERFACE for an IP
  if [ ! -z "${PROVISIONING_IP}" ];
  then
    echo "Waiting for ${PROVISIONING_IP} to be configured on an interface"
    export IRONIC_IP=$(ip -br addr show | grep "${PROVISIONING_IP}" | grep -Po "[^\s]+/[0-9]+" | sed -e 's%/.*%%' | head -n 1)
    # When an interface has multiple IP addresses, having IRONIC_IP set at this point means that the desired provisioning ip is set on the
    # interface. However, the address returned might not be the desired one (no control over the order), so setting it back to the
    # desired IP
    if [ ! -z "${IRONIC_IP}" ]; then
      export IRONIC_IP="$(echo ${PROVISIONING_IP} | sed -e 's%/.*%%' )"
    fi
  else
    echo "Waiting for ${PROVISIONING_INTERFACE} interface to be configured"
    export IRONIC_IP=$(ip -br add show scope global up dev "${PROVISIONING_INTERFACE}" | awk '{print $3}' | sed -e 's%/.*%%' | head -n 1)
  fi

  if [ ! -z "${IRONIC_IP}" ]; then
    # If the IP contains a colon, then it's an IPv6 address, and the HTTP
    # host needs surrounding with brackets
    if [[ "$IRONIC_IP" =~ .*:.* ]]
    then
      export IPV=6
      export IRONIC_URL_HOST="[$IRONIC_IP]"
    else
      export IPV=4
      export IRONIC_URL_HOST=$IRONIC_IP
    fi
  fi
}

function wait_for_interface_or_ip() {
  export IRONIC_IP=""
  until [ ! -z "${IRONIC_IP}" ]; do
    get_ironic_ip
    sleep 1
  done
}
