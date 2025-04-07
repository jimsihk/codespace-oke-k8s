# -----------------------------
# Build Kdash base image
# -----------------------------

#FROM oraclelinux:9 AS builder

#RUN dnf -y install git cargo

#WORKDIR /usr/src

# Download and compile Rust dependencies in an empty project and cache as a separate Docker layer
#RUN USER=root cargo new --bin kdash-temp

#RUN git clone https://github.com/kdash-rs/kdash.git /tmp && ls -l /tmp

#WORKDIR /usr/src/kdash-temp
#RUN cp /tmp/Cargo.* .
#RUN cargo build --release
# remove src from empty project
#RUN rm -r src
# Copy actual source files and Build the app binary
#RUN mv /tmp/kdash/src ./src
# remove previous deps
#RUN rm -r ./target/*/release/deps/kdash*

#RUN --mount=type=cache,target=/volume/target \
#    --mount=type=cache,target=/root/.cargo/registry \
#    cargo build --release --bin kdash
#RUN mv target/*/release/kdash .

# Base image licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
#FROM ghcr.io/oracle/oci-cli:latest
FROM oraclelinux:9
#FROM almalinux:9

USER root
# Install kubectl
RUN ARCH=$(uname -m) && \
    if [ "$ARCH" = "x86_64" ]; then ARCH="amd64"; elif [ "$ARCH" = "aarch64" ]; then ARCH="arm64"; else echo "Unsupported architecture"; exit 1; fi && \
    curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/${ARCH}/kubectl" && \
    curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/${ARCH}/kubectl.sha256" && \
    echo "$(cat kubectl.sha256)  kubectl" | sha256sum --check && \
    install -m 0755 kubectl /usr/local/bin/kubectl && \
    # Install git
    dnf -y install git && \
    # Install oci-cli
    dnf -y install oraclelinux-developer-release-el9 && \
    dnf install python39-oci-cli && \
    #curl -LO "https://raw.githubusercontent.com/oracle/oci-cli/master/scripts/install/install.sh" && \
    #chmod +x install.sh && ./install.sh --accept-all-defaults && \
    # Clean up
    rm -rf /var/cache/dnf/* && \
    # Install helm
    curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash && \
    # Install kdash
    #dnf -y install libxcb && \
    #curl https://raw.githubusercontent.com/kdash-rs/kdash/main/deployment/getLatest.sh | bash && \
    # Install kdash by docker
    #dnf -y install dnf-plugins-core && \
    #dnf config-manager --add-repo https://download.docker.com/linux/rhel/docker-ce.repo && \
    #dnf install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin && \
    #systemctl enable --now docker && \
    # Create user
    useradd -m -s /bin/bash oracle

#COPY --from=builder /usr/src/kdash-temp/kdash /usr/local/bin

# Debug
RUN ldd --version && id oracle

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
    source ~/.config/envman/PATH.env && \
    # Install kdash, with working user
    curl https://raw.githubusercontent.com/kdash-rs/kdash/main/deployment/getLatest.sh | bash && \
    #echo 'alias kdash=/oracle/kdash' >> ~/.bashrc && \
    # Setup kdash with docker
    #echo 'alias kdash=docker run --network host --rm -it -v ~/.kube/config:/root/.kube/config deepu105/kdash' >> ~/.bashrc && \
    # Verify
    echo "Installed versions:" && \
    echo "- oci: $(oci --version)" && \
    echo "- kubectl:" && kubectl version --client && \
    echo "- helm: $(helm version)" && \
    echo "- git: $(git --version)" && \
    echo "- k9s:" && k9s version && \
    echo "- kdash:" && ./kdash --version

ENTRYPOINT sleep infinity
