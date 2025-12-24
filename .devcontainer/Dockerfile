FROM alpine:3.23.0 AS builder

ENV KUBECTL_VERSION=v1.35.0
ENV HELM_VERSION=v3.19.4
ENV KDASH_VERSION=v0.6.2
ENV K9S_VERSION=v0.50.16
ENV OCI_CLI_VERSION=v3.71.4

USER root
RUN apk --no-cache add \
    curl \
    bash \
    openssl coreutils \
    #python3 py3-pip \
    python3 uv \
    # Install kubectl
    && ARCH="$(uname -m)" && echo "Detected: $ARCH" \
    && if [ "$ARCH" = "x86_64" ]; then ARCH="amd64"; elif [ "$ARCH" = "aarch64" ]; then ARCH="arm64"; else echo "Unsupported architecture"; exit 1; fi && echo "Converted: $ARCH" \
    && curl -LO "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/${ARCH}/kubectl" \
    && curl -LO "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/${ARCH}/kubectl.sha256" \
    && echo "$(cat kubectl.sha256)  kubectl" | sha256sum --check \
    && install -m 0755 kubectl /usr/local/bin/kubectl \
    # Install helm
    #&& curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash \
    && curl -L -O https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 \
    && bash get-helm-3 --version "${HELM_VERSION}" \
    # Install kdash
    #&& curl https://raw.githubusercontent.com/kdash-rs/kdash/main/deployment/getLatest.sh | sed "s/SUFFIX='linux.tar.gz'/SUFFIX='linux-musl.tar.gz'/" | sed "s/-gnu.tar.gz/-musl.tar.gz/g" | sed "s|/releases/latest|/releases/tags/${KDASH_VERSION}|g" | bash \
    # Install k9s
    && curl -sS "https://webi.sh/k9s@${K9S_VERSION}" | sh \
    # Install oci-cli
    #&& curl -L -O https://raw.githubusercontent.com/oracle/oci-cli/master/scripts/install/install.sh \
    #&& bash install.sh --accept-all-defaults --exec-dir /usr/local/bin --install-dir /usr/local/lib/oracle-cli --oci-cli-version "$(echo ${OCI_CLI_VERSION} | sed 's/v//g')"
    && echo "Running custom installation of oci-cli and kdash"

COPY hack /usr/local/lib/hack/
RUN chmod +x /usr/local/lib/hack/*

# Install oci-cli
# Replicate the logic of install.sh to download install.py directly
RUN curl -L -O "https://raw.githubusercontent.com/oracle/oci-cli/${OCI_CLI_VERSION}/scripts/install/install.py" \
    #curl -L -O "https://raw.githubusercontent.com/oracle/oci-cli/master/scripts/install/install.py" \
    # Manually patch the installation script to use uv for faster and smaller installation
    && export VIRTUAL_ENV=/usr/local/lib/oracle-cli \
    && /usr/local/lib/hack/patch-oci-install-py.sh install.py \
    && python install.py --accept-all-defaults --exec-dir /usr/local/bin --install-dir "${VIRTUAL_ENV}" --oci-cli-version "${OCI_CLI_VERSION}"

# Install kdash
RUN curl -L -O https://raw.githubusercontent.com/kdash-rs/kdash/main/deployment/getLatest.sh \
    # Manually patch the installation script to support musl and specify version
    && /usr/local/lib/hack/patch-kdash-getLatest-sh.sh getLatest.sh "${KDASH_VERSION}" \
    && bash getLatest.sh

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
