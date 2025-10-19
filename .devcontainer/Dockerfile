FROM alpine:3.22.2

USER root

RUN apk --no-cache add \
    kubectl \
    helm \
    git \
    oci-cli \
    k9s \
    curl \
    bash \
    procps-ng \
    && rm -rf /var/cache/apk/* \
    && curl https://raw.githubusercontent.com/kdash-rs/kdash/main/deployment/getLatest.sh | sed "s/SUFFIX='linux.tar.gz'/SUFFIX='linux-musl.tar.gz'/" | sed "s/-gnu.tar.gz/-musl.tar.gz/g" | bash \
    && adduser -D -h /oracle -s /bin/bash oracle

# Install kubectl
#RUN ARCH=$(uname -m) && echo "Detected: $ARCH" && \
#    if [ "$ARCH" = "x86_64" ]; then ARCH="amd64"; elif [ "$ARCH" = "aarch64" ]; then ARCH="arm64"; else echo "Unsupported architecture"; exit 1; fi && echo "Converted: $ARCH" && \
#    curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/${ARCH}/kubectl" && \
#    curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/${ARCH}/kubectl.sha256" && \
#    echo "$(cat kubectl.sha256)  kubectl" | sha256sum --check && \
#    install -m 0755 kubectl /usr/local/bin/kubectl && \
#    # Install git
#    dnf --nodocs -y install git && \
#    # Clean up
#    dnf clean all && \
#    # Install helm
#    curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash && \
#    # Install kdash
#    # Force to install musl version to avoid GLIBC error
#    curl https://raw.githubusercontent.com/kdash-rs/kdash/main/deployment/getLatest.sh | sed "s/SUFFIX='linux.tar.gz'/SUFFIX='linux-musl.tar.gz'/" | sed "s/-gnu.tar.gz/-musl.tar.gz/g" | bash

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
    #curl -sS https://webi.sh/k9s | sh
    pwd && ls -l && echo $HOME \
    cd && pwd && ls -l

# Launch bash as login shell to always load the .bashrc
ENTRYPOINT ["/bin/bash", "-l", "-c"]
CMD ["echo Started at $(date) && sleep infinity"]
