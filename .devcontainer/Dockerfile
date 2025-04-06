# Base image licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
FROM ghcr.io/oracle/oci-cli:latest

USER root
# Install kubectl
RUN ARCH=$(uname -m) && \
    if [ "$ARCH" = "x86_64" ]; then ARCH="amd64"; elif [ "$ARCH" = "aarch64" ]; then ARCH="arm64"; else echo "Unsupported architecture"; exit 1; fi && \
    curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/${ARCH}/kubectl" && \
    curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/${ARCH}/kubectl.sha256" && \
    echo "$(cat kubectl.sha256)  kubectl" | sha256sum --check && \
    install -m 0755 kubectl /usr/local/bin/kubectl && \
    # Install git
    dnf -y install git && rm -rf /var/cache/dnf/* && \
    # Install helm
    curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash && \
    # Install kdash
    curl https://raw.githubusercontent.com/kdash-rs/kdash/main/deployment/getLatest.sh | bash

COPY --chown=oracle okeutil /opt/okeutil/

USER oracle
WORKDIR /oracle
# Always create symbolic link to /workspaces as GitHub only clones only after build
RUN ln -s /workspaces ~/workspaces && \
    echo 'alias okectl=/opt/okeutil/okectl' >> ~/.bashrc && \
    echo 'alias ohelm=/opt/okeutil/ohelm' >> ~/.bashrc && \
    echo 'alias oapply=/opt/okeutil/oapply' >> ~/.bashrc && \
    echo 'alias odelete=/opt/okeutil/odelete' >> ~/.bashrc && \
    # Install k9s with working user as by default it will be installed to ~/.local
    curl -sS https://webinstall.dev/k9s | bash && \
    # Verify
    kubectl version --client && \
    helm version && \
    git --version && \
    kdash --version

ENTRYPOINT sleep infinity
