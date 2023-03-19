# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
FROM ghcr.io/oracle/oci-cli:latest

# Install git and kubectl
USER root
COPY kubernetes.repo /etc/yum.repos.d/
RUN dnf -y install git && rm -rf /var/cache/dnf/* \
    && yum install -y kubectl

COPY --chown=oracle okeutil /opt/okeutil/

USER oracle
WORKDIR /oracle
RUN ln -s /workspaces workspaces

ENTRYPOINT sleep infinity
