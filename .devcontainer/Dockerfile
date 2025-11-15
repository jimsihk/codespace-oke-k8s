FROM alpine:3.22.2 AS builder

USER root
RUN apk --no-cache add \
    curl \
    bash \
    openssl coreutils \
    # Install kubectl
    && ARCH="$(uname -m)" && echo "Detected: $ARCH" \
    && if [ "$ARCH" = "x86_64" ]; then ARCH="amd64"; elif [ "$ARCH" = "aarch64" ]; then ARCH="arm64"; else echo "Unsupported architecture"; exit 1; fi && echo "Converted: $ARCH" \
    && curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/${ARCH}/kubectl" \
    && curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/${ARCH}/kubectl.sha256" \
    && echo "$(cat kubectl.sha256)  kubectl" | sha256sum --check \
    && install -m 0755 kubectl /usr/local/bin/kubectl \
    # Install helm
    && curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash \
    # Install kdash
    && curl https://raw.githubusercontent.com/kdash-rs/kdash/main/deployment/getLatest.sh | sed "s/SUFFIX='linux.tar.gz'/SUFFIX='linux-musl.tar.gz'/" | sed "s/-gnu.tar.gz/-musl.tar.gz/g" | bash \
    # Install k9s
    && curl -sS https://webi.sh/k9s | sh

FROM alpine:3.22.2

USER root
RUN apk --no-cache add \
    git \
    #oci-cli \
    curl \
    bash \
    procps-ng \
    openssh-client-default \
    python3 \
    && rm -rf /var/cache/apk/* \
    # Install oci-cli
    && curl -LO https://github.com/oracle/oci-cli/archive/refs/tags/v3.70.1.tar.gz \
    && tar fxz v3.70.1.tar.gz \
    #&& curl -LO https://github.com/oracle/oci-cli/releases/download/v3.70.1/oci-cli-3.70.1.zip \
    #&& unzip oci-cli-3.70.1.zip \
    && echo "=== Current path: `pwd` ===" && ls -l \
    && bash oci-cli-3.70.1/scripts/install/install.sh --offline-install \
    # Create the oracle user which does not exist
    && adduser -D -h /oracle -s /bin/bash oracle

COPY --from=builder /usr/local/bin/kubectl /usr/local/bin/kubectl
COPY --from=builder /usr/local/bin/helm /usr/local/bin/helm
COPY --from=builder /usr/local/bin/kdash /usr/local/bin/kdash
COPY --from=builder /root/.local/bin/k9s /usr/local/bin/k9s

COPY --chown=oracle okeutil /opt/okeutil/

USER oracle
WORKDIR /oracle
# Always create symbolic link to /workspaces as GitHub only clones only after build
RUN ln -s /workspaces ~/workspaces && \
    echo 'export PATH="/opt/okeutil:$PATH"' >> ~/.bash_profile && \
    echo 'alias okectl=/opt/okeutil/okectl' >> ~/.bash_profile && \
    echo 'alias ohelm=/opt/okeutil/ohelm' >> ~/.bash_profile && \
    echo 'alias oapply=/opt/okeutil/oapply' >> ~/.bash_profile && \
    echo 'alias odelete=/opt/okeutil/odelete' >> ~/.bash_profile

# Launch bash as login shell to always load the .bash_profile
ENTRYPOINT ["/bin/bash", "-l", "-c"]
CMD ["echo Started at $(date) && sleep infinity"]
