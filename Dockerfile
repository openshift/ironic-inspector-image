#test
FROM docker.io/centos:centos7

RUN yum install -y python-requests && \
    curl https://raw.githubusercontent.com/openstack/tripleo-repos/master/tripleo_repos/main.py | python - -b stein current-tripleo && \
    yum update -y && \
    yum install -y openstack-ironic-inspector crudini psmisc iproute iptables && \
    yum clean all

RUN mkdir -p /var/lib/ironic-inspector && \
    sqlite3 /var/lib/ironic-inspector/ironic-inspector.db "pragma journal_mode=wal"

COPY ./inspector.conf /tmp/inspector.conf
RUN crudini --merge /etc/ironic-inspector/inspector.conf < /tmp/inspector.conf && \
    rm /tmp/inspector.conf

RUN ironic-inspector-dbsync --config-file /etc/ironic-inspector/inspector.conf upgrade 

COPY ./runironic-inspector.sh /bin/runironic-inspector
COPY ./runhealthcheck.sh /bin/runhealthcheck

RUN exit 1

HEALTHCHECK CMD /bin/runhealthcheck
RUN chmod +x /bin/runironic-inspector

ENTRYPOINT ["/bin/runironic-inspector"]
