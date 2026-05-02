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
    && uv pip install "oci-cli==${OCI_CLI_VERSION#v}" \
    && find "${VIRTUAL_ENV}/lib" \( -name '_virtualenv.pth' -o -name '_virtualenv.py' \) -delete \
    # Rebuild all .pyc files as checked-hash bytecode so they remain valid when overlaid
    # onto the target-architecture venv, whose source mtimes differ from this native stage.
    && find "${VIRTUAL_ENV}/lib" -type f -name '*.pyc' -delete \
    && python3 -m compileall -q -f -j 0 --invalidation-mode checked-hash "${VIRTUAL_ENV}/lib" \
    && cd "${VIRTUAL_ENV}/lib" \
    && find . -type f -name '*.pyc' > /tmp/oci-pyc.list \
    && [ -s /tmp/oci-pyc.list ] || { echo "No compiled OCI bytecode files were generated" >&2; exit 1; } \
    && tar -cf /tmp/oci-pyc.tar -T /tmp/oci-pyc.list \
    && rm -f /tmp/oci-pyc.list

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
    && HELM_VERSION_NO_PREFIX="${HELM_VERSION#v}" \
    && if ! printf '%s\n' "${HELM_VERSION}" | grep -Eq '^v?[0-9]+\.[0-9]+\.[0-9]+$'; then echo "Invalid HELM_VERSION format: expected vX.Y.Z or X.Y.Z but got ${HELM_VERSION}. Please set HELM_VERSION to a valid semantic version such as v3.12.0 or 3.12.0." >&2; exit 1; fi \
    && HELM_MAJOR_VERSION="${HELM_VERSION_NO_PREFIX%%.*}" \
    && HELM_INSTALL_SCRIPT="get-helm-${HELM_MAJOR_VERSION}" \
    && curl -LO "https://raw.githubusercontent.com/helm/helm/main/scripts/${HELM_INSTALL_SCRIPT}" \
    && bash "${HELM_INSTALL_SCRIPT}" --version "${HELM_VERSION}" \
    # Install k9s
    && curl -sS "https://webi.sh/k9s@${K9S_VERSION}" | sh

COPY hack/patch-kdash-getLatest-sh.sh /usr/local/lib/hack/patch-kdash-getLatest-sh.sh
RUN chmod +x /usr/local/lib/hack/patch-kdash-getLatest-sh.sh

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

RUN apk --no-cache add \
    git=${GIT_VERSION} \
    curl=${CURL_VERSION} \
    bash=${BASH_VERSION} \
    # Install pgrep for OCI bastion session clean up
    procps-ng=${PROCPS_NG_VERSION} \
    # Install ssh and ssh-keygen for OCI bastion tunneling
    openssh-client-default=${OPENSSH_VERSION} \
    python3=${PYTHON_VERSION} \
    && rm -rf /var/cache/apk/* \
    # Create the oracle user for backward compatibility
    && adduser -D -h /oracle -s /bin/bash oracle \
    # Set permission for utility scripts
    && chmod -R 755 /opt/okeutil/

USER oracle
WORKDIR /oracle
# Always create symbolic link to /workspaces as GitHub only clones only after build
RUN ln -s /workspaces ~/workspaces \
    && echo 'export PATH="/opt/okeutil:$PATH"' >> ~/.bash_profile \
    && cat ~/.bash_profile

# Launch bash as login shell to always load the .bash_profile
ENTRYPOINT ["/bin/bash", "-l", "-c"]
CMD ["echo Started at $(date) && sleep infinity"]
