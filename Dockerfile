FROM centos:7
MAINTAINER Richard Guest <r.guest@gns.cri.nz>

COPY sd-packaging-public.key /etc/pki/rpm-gpg/RPM-GPG-KEY-serverdensity
COPY sd.repo /etc/yum.repos.d/sd.repo

RUN yum install -y sd-agent sd-agent-docker && \
	yum clean all

RUN sed -i -e"s/^.*log_to_syslog:.*$/log_to_syslog: no/" /etc/sd-agent/config.cfg && \
	sed -i "/user=sd-agent/d" /etc/sd-agent/supervisor.conf && \
	sed -i 's/AGENTUSER="sd-agent"/AGENTUSER="root"/g' /etc/init.d/sd-agent

COPY docker.yaml /etc/sd-agent/conf.d/docker.yaml
COPY entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
CMD ["supervisord", "-n", "-c", "/etc/sd-agent/supervisor.conf"]
