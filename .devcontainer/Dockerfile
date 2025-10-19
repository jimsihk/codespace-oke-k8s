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

# Launch bash as login shell to always load the .bashrc
ENTRYPOINT ["/bin/bash", "-l", "-c"]
CMD ["echo Started at $(date) && sleep infinity"]
