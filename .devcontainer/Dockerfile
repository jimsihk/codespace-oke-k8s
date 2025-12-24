FROM alpine:3.23.0 AS builder

USER root
RUN apk --no-cache add \
    curl \
    bash \
    openssl coreutils \
    # python3 py3-pip \
    python3 uv \
    # Install kubectl
    && ARCH="$(uname -m)" && echo "Detected: $ARCH" \
    && if [ "$ARCH" = "x86_64" ]; then ARCH="amd64"; elif [ "$ARCH" = "aarch64" ]; then ARCH="arm64"; else echo "Unsupported architecture"; exit 1; fi && echo "Converted: $ARCH" \
    && curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/${ARCH}/kubectl" \
    && curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/${ARCH}/kubectl.sha256" \
    && echo "$(cat kubectl.sha256)  kubectl" | sha256sum --check \
    && install -m 0755 kubectl /usr/local/bin/kubectl \
    # Install helm
    #&& curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash \
    && curl -L -O https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 \
    && bash get-helm-3 --version 3.19.4 \
    # Install kdash
    && curl https://raw.githubusercontent.com/kdash-rs/kdash/main/deployment/getLatest.sh | sed "s/SUFFIX='linux.tar.gz'/SUFFIX='linux-musl.tar.gz'/" | sed "s/-gnu.tar.gz/-musl.tar.gz/g" | bash \
    # Install k9s
    && curl -sS https://webi.sh/k9s@v0.50.16 | sh \
    # Install oci-cli
    #&& curl -L -O https://raw.githubusercontent.com/oracle/oci-cli/master/scripts/install/install.sh \
    #&& bash install.sh --accept-all-defaults --exec-dir /usr/local/bin --install-dir /usr/local/lib/oracle-cli
    && echo "Running custom installation of oci-cli"

COPY hack /usr/local/lib/hack/
RUN curl -L -O https://raw.githubusercontent.com/oracle/oci-cli/master/scripts/install/install.py \
    # Manually patch the script to use uv for faster installation
    && export VIRTUAL_ENV=/usr/local/lib/oracle-cli \
    && chmod +x /usr/local/lib/hack/* \
    && /usr/local/lib/hack/patch-oci-install-py.sh install.py \
    && python install.py --accept-all-defaults --exec-dir /usr/local/bin --install-dir "$VIRTUAL_ENV"

FROM alpine:3.23.0

USER root

COPY --from=builder /usr/local/bin/kubectl /usr/local/bin/kubectl
COPY --from=builder /usr/local/bin/helm /usr/local/bin/helm
COPY --from=builder /usr/local/bin/kdash /usr/local/bin/kdash
COPY --from=builder /root/.local/bin/k9s /usr/local/bin/k9s
COPY --from=builder /usr/local/bin/oci /usr/local/bin/oci
COPY --from=builder /usr/local/lib/oracle-cli /usr/local/lib/oracle-cli

COPY okeutil /opt/okeutil/

RUN apk --no-cache add \
    git \
    #oci-cli \
    curl \
    bash \
    procps-ng \
    openssh-client-default \
    python3 \
    && rm -rf /var/cache/apk/* \
    # Create the oracle user which does not exist
    && adduser -D -h /oracle -s /bin/bash oracle \
    && chmod -R 755 /opt/okeutil/

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
