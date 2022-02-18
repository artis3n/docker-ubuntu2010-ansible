FROM ubuntu:20.10
LABEL maintainer="Artis3n"

ENV pip_packages "ansible"

WORKDIR /

# Fix EOL issue by pointing to focal
RUN sed -i 's/groovy/focal/g' /etc/apt/sources.list \
    && apt-get update \
    && apt-get install -y --no-install-recommends \
       apt-utils \
       locales \
       python3-setuptools \
       python3-wheel \
       python3-pip \
       software-properties-common \
       rsyslog systemd systemd-cron sudo iproute2 \
    && rm -Rf /var/lib/apt/lists/* \
    && rm -Rf /usr/share/doc && rm -Rf /usr/share/man \
    && apt-get clean

# Remove unnecessary getty and udev targets that result in high CPU usage when using
# multiple containers with Molecule (https://github.com/ansible/molecule/issues/1104)
#
# Install Ansible inventory file.
#
# Fix potential UTF-8 errors with ansible-test.
RUN sed -i 's/^\($ModLoad imklog\)/#\1/' /etc/rsyslog.conf \
    && rm -f /lib/systemd/system/systemd*udev* \
    && rm -f /lib/systemd/system/getty.target \
    && mkdir -p /etc/ansible \
    && printf "[local]\nlocalhost ansible_connection=local" > /etc/ansible/hosts \
    && locale-gen en_US.UTF-8

# Install Ansible via Pip.
RUN pip3 install --no-cache-dir $pip_packages

COPY initctl_faker .
RUN chmod +x initctl_faker && rm -fr /sbin/initctl && ln -s /initctl_faker /sbin/initctl

VOLUME ["/sys/fs/cgroup", "/tmp", "/run"]
CMD ["/lib/systemd/systemd"]
