FROM alpine:3.23.0 AS builder

ARG KUBECTL_VERSION=v1.35.0
ARG HELM_VERSION=v3.19.4
ARG KDASH_VERSION=v0.6.2
ARG K9S_VERSION=v0.50.16
ARG OCI_CLI_VERSION=v3.71.4
ARG PYTHON_VERSION=3.12.12-r0

USER root
RUN apk --no-cache add \
    curl \
    bash \
    openssl \
    # Replace sha256sum with GNU version for checksum in kubectl
    coreutils \
    python3=${PYTHON_VERSION} \
    # Install uv to replace pip for better performance on oci-cli installation
    # uv \
    # Install kubectl
    && ARCH="$(uname -m)" && echo "Detected: $ARCH" \
    && if [ "$ARCH" = "x86_64" ]; then ARCH="amd64"; elif [ "$ARCH" = "aarch64" ]; then ARCH="arm64"; else echo "Unsupported architecture"; exit 1; fi && echo "Converted: $ARCH" \
    && curl -LO "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/${ARCH}/kubectl" \
    && curl -LO "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/${ARCH}/kubectl.sha256" \
    && echo "$(cat kubectl.sha256)  kubectl" | sha256sum --check \
    && install -m 0755 kubectl /usr/local/bin/kubectl \
    # Install helm
    && curl -LO "https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3" \
    && bash get-helm-3 --version "${HELM_VERSION}" \
    # Install k9s
    && curl -sS "https://webi.sh/k9s@${K9S_VERSION}" | sh

COPY hack /usr/local/lib/hack/
RUN chmod +x /usr/local/lib/hack/*

# Install oci-cli
# Replicate the logic of install.sh to download install.py directly
RUN curl -LO "https://raw.githubusercontent.com/oracle/oci-cli/${OCI_CLI_VERSION}/scripts/install/install.py" \
    # Manually patch the installation script to use uv for faster and smaller installation
    && export VIRTUAL_ENV=/usr/local/lib/oracle-cli \
    && /usr/local/lib/hack/patch-oci-install-py.sh install.py
#     && python install.py --accept-all-defaults --exec-dir /usr/local/bin --install-dir "${VIRTUAL_ENV}" --oci-cli-version "${OCI_CLI_VERSION}"

# Install kdash
RUN curl -LO "https://raw.githubusercontent.com/kdash-rs/kdash/main/deployment/getLatest.sh" \
    # Manually patch the installation script to support musl and specify version
    && /usr/local/lib/hack/patch-kdash-getLatest-sh.sh getLatest.sh "${KDASH_VERSION}" \
    && bash getLatest.sh

FROM alpine:3.23.0

ARG PYTHON_VERSION=3.12.12-r0
ARG OCI_CLI_VERSION=v3.71.4

USER root

COPY --from=builder /usr/local/bin/kubectl /usr/local/bin/kubectl
COPY --from=builder /usr/local/bin/helm /usr/local/bin/helm
COPY --from=builder /usr/local/bin/kdash /usr/local/bin/kdash
COPY --from=builder /root/.local/bin/k9s /usr/local/bin/k9s
COPY --from=builder /usr/local/bin/oci /usr/local/bin/oci
# COPY --from=builder /usr/local/lib/oracle-cli /usr/local/lib/oracle-cli
# COPY --from=builder /usr/local/lib/oracle-cli/lib/python*/site-packages/oci_cli/bin/oci_autocomplete.sh /usr/local/bin/oci_autocomplete.sh

COPY okeutil /opt/okeutil/

RUN apk --no-cache add \
    git \
    curl \
    bash \
    # Install pgrep for OCI bastion session clean up
    procps-ng \
    # Install ssh and ssh-keygen for OCI bastion tunneling
    openssh-client-default \
    python3=${PYTHON_VERSION} \
    # Install uv to replace pip for better performance on oci-cli installation
    uv \
    && rm -rf /var/cache/apk/* \
    # Create the oracle user for backward compatibility
    && adduser -D -h /oracle -s /bin/bash oracle \
    # Set permission for utility scripts
    && chmod -R 755 /opt/okeutil/
    # && chmod +x /usr/local/bin/oci_autocomplete.sh

USER oracle
WORKDIR /oracle
# Always create symbolic link to /workspaces as GitHub only clones only after build
RUN ln -s /workspaces ~/workspaces \
    && echo 'export PATH="/opt/okeutil:$PATH"' >> ~/.bash_profile \
    && echo 'alias okectl=/opt/okeutil/okectl' >> ~/.bash_profile \
    && echo 'alias ohelm=/opt/okeutil/ohelm' >> ~/.bash_profile \
    && echo 'alias oapply=/opt/okeutil/oapply' >> ~/.bash_profile \
    && echo 'alias odelete=/opt/okeutil/odelete' >> ~/.bash_profile
    # && echo '[[ -e "/usr/local/bin/oci_autocomplete.sh" ]] && source "/usr/local/bin/oci_autocomplete.sh"' >> ~/.bash_profile

COPY --from=builder /install.py /oracle/install.py
RUN export VIRTUAL_ENV=/usr/local/lib/oracle-cli \
    && python install.py --accept-all-defaults --exec-dir /usr/local/bin --install-dir "${VIRTUAL_ENV}" --oci-cli-version "${OCI_CLI_VERSION}"

# Launch bash as login shell to always load the .bash_profile
ENTRYPOINT ["/bin/bash", "-l", "-c"]
CMD ["echo Started at $(date) && sleep infinity"]
