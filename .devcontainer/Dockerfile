# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
FROM ghcr.io/oracle/oci-cli:latest

# Install git, kubectl, helm, kdash
USER root
COPY kubernetes.repo /etc/yum.repos.d/
RUN dnf -y install git && rm -rf /var/cache/dnf/* \
    && yum install -y kubectl \
    && curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash \
    && curl https://raw.githubusercontent.com/kdash-rs/kdash/main/deployment/getLatest.sh | bash

COPY --chown=oracle okeutil /opt/okeutil/

USER oracle
WORKDIR /oracle
# Always create symbolic link to /workspaces as GitHub only clones only after build
RUN ln -s /workspaces ~/workspaces \
    && echo 'alias okectl=/opt/okeutil/okectl' >> ~/.bashrc \
    && echo 'alias ohelm=/opt/okeutil/ohelm' >> ~/.bashrc \
    && echo 'alias oapply=/opt/okeutil/oapply' >> ~/.bashrc \
    && echo 'alias odelete=/opt/okeutil/odelete' >> ~/.bashrc \
    # Install k9s with working user as by default it will be installed to ~/.local
    && curl -sS https://webinstall.dev/k9s | bash

ENTRYPOINT sleep infinity
