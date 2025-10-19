FROM oraclelinux:9-slim AS builder

USER root
# Install kubectl
RUN ARCH=$(uname -m) && echo "Detected: $ARCH" && \
    if [ "$ARCH" = "x86_64" ]; then ARCH="amd64"; elif [ "$ARCH" = "aarch64" ]; then ARCH="arm64"; else echo "Unsupported architecture"; exit 1; fi && echo "Converted: $ARCH" && \
    curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/${ARCH}/kubectl" && \
    curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/${ARCH}/kubectl.sha256" && \
    echo "$(cat kubectl.sha256)  kubectl" | sha256sum --check && \
    install -m 0755 kubectl /usr/local/bin/kubectl && \
    # Install helm
    curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash && \
    # Install kdash
    # Force to install musl version to avoid GLIBC error
    curl https://raw.githubusercontent.com/kdash-rs/kdash/main/deployment/getLatest.sh | sed "s/SUFFIX='linux.tar.gz'/SUFFIX='linux-musl.tar.gz'/" | sed "s/-gnu.tar.gz/-musl.tar.gz/g" | bash

FROM oraclelinux:9-slim

USER root
RUN microdnf --nodocs -y install \
# Install kubectl
#RUN ARCH=$(uname -m) && echo "Detected: $ARCH" && \
    #if [ "$ARCH" = "x86_64" ]; then ARCH="amd64"; elif [ "$ARCH" = "aarch64" ]; then ARCH="arm64"; else echo "Unsupported architecture"; exit 1; fi && echo "Converted: $ARCH" && \
    #curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/${ARCH}/kubectl" && \
    #curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/${ARCH}/kubectl.sha256" && \
    #echo "$(cat kubectl.sha256)  kubectl" | sha256sum --check && \
    #install -m 0755 kubectl /usr/local/bin/kubectl && \
    # Install git
    git \
    #microdnf --nodocs -y install git && \
    # Install pgrep
    procps-ng \
    #microdnf --nodocs -y install procps-ng && \
    # Install oci cli
    python3.9-pip && \
    #microdnf --nodocs -y install oraclelinux-developer-release-el9 && \
    #microdnf --nodocs install python39-oci-cli && \
    #microdnf --nodocs install python3.9 && \
    #microdnf --nodocs install python3.9-pip && \
    python3 -m pip install --no-cache-dir oci-cli && \
    # Create the oracle user which does not exist by default in Oracle Linux 9
    useradd -m -d /oracle -s /bin/bash oracle && \
    # Clean up
    # rm -rf /var/cache/dnf/* && \
    microdnf clean all
    # Install helm
    #curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash && \
    # Install kdash
    # Force to install musl version to avoid GLIBC error
    #curl https://raw.githubusercontent.com/kdash-rs/kdash/main/deployment/getLatest.sh | sed "s/SUFFIX='linux.tar.gz'/SUFFIX='linux-musl.tar.gz'/" | sed "s/-gnu.tar.gz/-musl.tar.gz/g" | bash

COPY --from=builder /usr/local/bin/kubectl /usr/local/bin/kubectl
COPY --from=builder /usr/local/bin/helm /usr/local/bin/helm
COPY --from=builder /usr/local/bin/kdash /usr/local/bin/kdash

COPY --chown=oracle okeutil /opt/okeutil/

USER oracle
WORKDIR /oracle
# Always create symbolic link to /workspaces as GitHub only clones only after build
RUN ln -s /workspaces ~/workspaces && \
    echo 'export PATH="/opt/okeutil:$PATH"' >> ~/.bashrc && \
    #echo 'alias okectl=/opt/okeutil/okectl' >> ~/.bashrc && \
    #echo 'alias ohelm=/opt/okeutil/ohelm' >> ~/.bashrc && \
    #echo 'alias oapply=/opt/okeutil/oapply' >> ~/.bashrc && \
    #echo 'alias odelete=/opt/okeutil/odelete' >> ~/.bashrc && \
    # Install k9s, with working user as webi will update .bashrc of current user
    curl -sS https://webi.sh/k9s | sh

# Launch bash as login shell to always load the .bashrc
ENTRYPOINT ["/bin/bash", "-l", "-c"]
CMD ["echo Started at $(date) && sleep infinity"]
