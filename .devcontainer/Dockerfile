# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

FROM ghcr.io/oracle/oci-cli:latest

USER root

COPY build/cloud-shell/kubernetes.repo /etc/yum.repos.d/
RUN dnf -y install git && rm -rf /var/cache/dnf/* \
    && yum install -y kubectl

USER oracle
WORKDIR /oracle
RUN if [ -d /workspaces ]; then ln -s /workspaces workspaces; fi

ENTRYPOINT sleep infinity
