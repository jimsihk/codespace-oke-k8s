# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
FROM ghcr.io/oracle/oci-cli:latest

# Install git, kubectl, helm
USER root
COPY kubernetes.repo /etc/yum.repos.d/
RUN dnf -y install git && rm -rf /var/cache/dnf/* \
    && yum install -y kubectl \
    && curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

COPY --chown=oracle okeutil /opt/okeutil/

USER oracle
WORKDIR /oracle
RUN if [ -d /workspaces ]; then ln -s /workspaces /oracle/workspaces; fi \
    && echo 'alias okectl=/opt/okeutil/okectl' >> /oracle/.bashrc \
    && echo 'alias oapply=/opt/okeutil/oapply' >> /oracle/.bashrc \
    && echo 'alias odelete=/opt/okeutil/odelete' >> /oracle/.bashrc

ENTRYPOINT sleep infinity
