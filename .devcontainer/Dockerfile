# Base image licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
FROM ghcr.io/oracle/oci-cli:latest

USER root
# Install kubectl
RUN ARCH=$(uname -m) && echo "Detected: $ARCH" && \
    if [ "$ARCH" = "x86_64" ]; then ARCH="amd64"; elif [ "$ARCH" = "aarch64" ]; then ARCH="arm64"; else echo "Unsupported architecture"; exit 1; fi && echo "Converted: $ARCH" && \
    curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/${ARCH}/kubectl" && \
    curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/${ARCH}/kubectl.sha256" && \
    echo "$(cat kubectl.sha256)  kubectl" | sha256sum --check && \
    install -m 0755 kubectl /usr/local/bin/kubectl && \
    # Install git
    dnf -y install git && \
    # Clean up
    rm -rf /var/cache/dnf/* && \
    # Install helm
    curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash && \
    # Install kdash
    # Force to install musl version to avoid GLIBC error
    curl https://raw.githubusercontent.com/kdash-rs/kdash/main/deployment/getLatest.sh | sed "s/SUFFIX='linux.tar.gz'/SUFFIX='linux-musl.tar.gz'/" | sed "s/-gnu.tar.gz/-musl.tar.gz/g" | bash

COPY --chown=oracle okeutil /opt/okeutil/

USER oracle
WORKDIR /oracle
# Always create symbolic link to /workspaces as GitHub only clones only after build
RUN ln -s /workspaces ~/workspaces && \
    echo 'alias okectl=/opt/okeutil/okectl' >> ~/.bashrc && \
    echo 'alias ohelm=/opt/okeutil/ohelm' >> ~/.bashrc && \
    echo 'alias oapply=/opt/okeutil/oapply' >> ~/.bashrc && \
    echo 'alias odelete=/opt/okeutil/odelete' >> ~/.bashrc && \
    # Install k9s, with working user as by default it will be installed to ~/.local
    curl -sS https://webi.sh/k9s | sh && \
    . ~/.config/envman/PATH.env && \
    echo '. ~/.config/envman/PATH.env' >> ~/.bashrc && \
    # Verify
    echo "Installed versions:" && \
    echo "- oci: $(oci --version)" && \
    echo "- kubectl:" && kubectl version --client && \
    echo "- helm: $(helm version)" && \
    echo "- git: $(git --version)" && \
    echo "- k9s:" && k9s version && \
    echo "- kdash: $(kdash --version)"

# Debug
RUN cat ~/.bashrc
RUN cat ~/.config/envman/PATH.env

ENTRYPOINT ["/bin/bash", "-c"]
CMD ["sleep", "infinity"]
