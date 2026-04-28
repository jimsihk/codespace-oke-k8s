##########################################
# Native bytecode compiler stage
# Runs on the BUILD platform (e.g. amd64) regardless of the target platform.
# Python .pyc bytecode is architecture-independent for the same Python version,
# so we compile once natively (fast) and copy __pycache__ dirs to any target arch.
##########################################
FROM --platform=$BUILDPLATFORM alpine:3.23.4 AS oci-pyc-builder

ARG PYTHON_VERSION=3.12.13-r0
ARG UV_VERSION=0.10.2-r0
ARG OCI_CLI_VERSION=v3.80.0

RUN apk --no-cache add python3=${PYTHON_VERSION} uv=${UV_VERSION} \
    && export VIRTUAL_ENV=/usr/local/lib/oracle-cli \
    && python3 -m venv --without-pip "$VIRTUAL_ENV" \
    # OCI_CLI_VERSION is expected in 'vX.Y.Z' format; strip leading 'v' for PyPI package version
    && uv pip install --compile-bytecode "oci-cli==${OCI_CLI_VERSION#v}" \
    && find "${VIRTUAL_ENV}/lib" \( -name '_virtualenv.pth' -o -name '_virtualenv.py' \) -delete \
    && cd "${VIRTUAL_ENV}/lib" \
    && find . -type f -name '*.pyc' | tar -cf /tmp/oci-pyc.tar -T -

##########################################
# Main builder stage (target architecture)
##########################################
FROM alpine:3.23.4 AS builder

ARG KUBECTL_VERSION=v1.36.0
ARG HELM_VERSION=v4.1.4
ARG KDASH_VERSION=v1.1.1
ARG K9S_VERSION=v0.50.18
ARG OCI_CLI_VERSION=v3.80.0
ARG PYTHON_VERSION=3.12.13-r0
ARG CURL_VERSION=8.17.0-r1
ARG BASH_VERSION=5.3.3-r1
ARG OPENSSL_VERSION=3.5.6-r0
ARG COREUTILS_VERSION=9.8-r1
ARG UV_VERSION=0.10.2-r0

USER root
RUN apk --no-cache add \
    curl=${CURL_VERSION} \
    bash=${BASH_VERSION} \
    openssl=${OPENSSL_VERSION} \
    # Replace sha256sum with GNU version for checksum in kubectl
    coreutils=${COREUTILS_VERSION} \
    python3=${PYTHON_VERSION} \
    # py3-pip \
    # Install uv to replace pip for better performance on oci-cli installation
    uv=${UV_VERSION} \
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
# Install packages for the target architecture without bytecode compilation;
# bytecode will be overlaid from the native oci-pyc-builder stage below.
RUN export VIRTUAL_ENV=/usr/local/lib/oracle-cli \
    # Create a standard Python venv (no _virtualenv.pth startup hooks from uv venv)
    && python3 -m venv --without-pip "$VIRTUAL_ENV" \
    # OCI_CLI_VERSION is expected in 'vX.Y.Z' format; strip leading 'v' for PyPI package version
    && uv pip install "oci-cli==${OCI_CLI_VERSION#v}" \
    # Remove any _virtualenv startup hooks that may have been injected by uv or dependencies
    && find "${VIRTUAL_ENV}/lib" \( -name '_virtualenv.pth' -o -name '_virtualenv.py' \) -delete \
    # Copy the pip-generated oci entry-point script to PATH
    && cp "${VIRTUAL_ENV}/bin/oci" /usr/local/bin/oci

# Overlay pre-compiled Python bytecode from the native (BUILDPLATFORM) build.
# Python .pyc files are architecture-independent for the same Python version,
# so this provides fast oci startup on all target architectures without QEMU overhead.
COPY --from=oci-pyc-builder /tmp/oci-pyc.tar /tmp/oci-pyc.tar
RUN tar -xf /tmp/oci-pyc.tar -C /usr/local/lib/oracle-cli/lib \
    && rm -f /tmp/oci-pyc.tar

# Install kdash
RUN curl -LO "https://raw.githubusercontent.com/kdash-rs/kdash/main/deployment/getLatest.sh" \
    # Manually patch the installation script to support musl and specify version
    && /usr/local/lib/hack/patch-kdash-getLatest-sh.sh getLatest.sh "${KDASH_VERSION}" \
    && bash getLatest.sh

##########################################
# Build final container
##########################################

FROM alpine:3.23.4

ARG PYTHON_VERSION=3.12.13-r0
ARG CURL_VERSION=8.17.0-r1
ARG BASH_VERSION=5.3.3-r1
ARG GIT_VERSION=2.52.0-r0
ARG PROCPS_NG_VERSION=4.0.5-r0
ARG OPENSSH_VERSION=10.2_p1-r0

USER root

COPY --from=builder /usr/local/bin/kubectl /usr/local/bin/kubectl
COPY --from=builder /usr/local/bin/helm /usr/local/bin/helm
COPY --from=builder /usr/local/bin/kdash /usr/local/bin/kdash
COPY --from=builder /root/.local/bin/k9s /usr/local/bin/k9s
COPY --from=builder /usr/local/bin/oci /usr/local/bin/oci
COPY --from=builder /usr/local/lib/oracle-cli /usr/local/lib/oracle-cli
COPY --from=builder /usr/local/lib/oracle-cli/lib/python*/site-packages/oci_cli/bin/oci_autocomplete.sh /usr/local/bin/oci_autocomplete.sh

COPY okeutil /opt/okeutil/

# For install oci-cli
# COPY hack /usr/local/lib/hack/
# RUN chmod +x /usr/local/lib/hack/*

RUN apk --no-cache add \
    git=${GIT_VERSION} \
    curl=${CURL_VERSION} \
    bash=${BASH_VERSION} \
    # Install pgrep for OCI bastion session clean up
    procps-ng=${PROCPS_NG_VERSION} \
    # Install ssh and ssh-keygen for OCI bastion tunneling
    openssh-client-default=${OPENSSH_VERSION} \
    python3=${PYTHON_VERSION} \
    # py3-pip \
    # oci-cli \
    && rm -rf /var/cache/apk/* \
    # Create the oracle user for backward compatibility
    && adduser -D -h /oracle -s /bin/bash oracle \
    # Set permission for utility scripts
    # && chmod +x /usr/local/bin/oci_autocomplete.sh \
    && chmod -R 755 /opt/okeutil/

USER oracle
WORKDIR /oracle
# Always create symbolic link to /workspaces as GitHub only clones only after build
RUN ln -s /workspaces ~/workspaces \
    && echo 'export PATH="/opt/okeutil:$PATH"' >> ~/.bash_profile \
    # && echo '[[ -e "/usr/local/bin/oci_autocomplete.sh" ]] && source "/usr/local/bin/oci_autocomplete.sh"' >> ~/.bash_profile
    # && echo 'source "/usr/local/bin/oci_autocomplete.sh"' >> ~/.bash_profile
    && cat ~/.bash_profile

# Install oci-cli
# ARG OCI_CLI_VERSION=v3.71.4
# RUN curl -LO "https://raw.githubusercontent.com/oracle/oci-cli/${OCI_CLI_VERSION}/scripts/install/install.py" \
    # Manually patch the installation script to use uv for faster and smaller installation
    # && export VIRTUAL_ENV=/oracle/lib/oracle-cli \
    # && /usr/local/lib/hack/patch-oci-install-py.sh install.py \
    # && python install.py --accept-all-defaults --exec-dir /oracle/bin --install-dir "${VIRTUAL_ENV}" --oci-cli-version "${OCI_CLI_VERSION}"

# Launch bash as login shell to always load the .bash_profile
ENTRYPOINT ["/bin/bash", "-l", "-c"]
CMD ["echo Started at $(date) && sleep infinity"]
