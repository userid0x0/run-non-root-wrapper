ARG BASEIMAGE=docker.io/library/debian:trixie-slim

# ---

FROM ${BASEIMAGE} AS downloader-amd64

ADD --chown=root:root \
    --chmod=755 \
    https://github.com/krallin/tini/releases/download/v0.19.0/tini-static-amd64 \
    /patch/usr/local/bin/tini

ADD --chown=root:root \
    --chmod=755 \
    https://github.com/ncopa/su-exec/releases/download/v0.3/su-exec-static-v0.3-x86_64 \
    /patch/usr/local/bin/su-exec

FROM ${BASEIMAGE} AS downloader-arm64

ADD --chown=root:root \
    --chmod=755 \
    https://github.com/krallin/tini/releases/download/v0.19.0/tini-static-arm64 \
    /patch/usr/local/bin/tini

ADD --chown=root:root \
    --chmod=755 \
    https://github.com/ncopa/su-exec/releases/download/v0.3/su-exec-static-v0.3-arm64 \
    /patch/usr/local/bin/su-exec

FROM downloader-${TARGETARCH} AS downloader

ADD --chown=root:root \
    --chmod=755 \
    https://raw.githubusercontent.com/creemama/run-non-root/v1.5.1/run-non-root.sh \
    /patch/usr/local/bin/run-non-root

ADD --chown=root:root \
    --chmod=755 \
    https://raw.githubusercontent.com/userid0x0/run-non-root-wrapper/master/run-non-root-wrapper.sh \
    /patch/usr/local/bin/run-non-root-wrapper

# ---

FROM ${BASEIMAGE}

COPY --from=downloader /patch /

RUN mkdir -p /home/nonroot_fallback \
    && chmod 777 /home/nonroot_fallback

VOLUME "/app"
WORKDIR "/app"

ENTRYPOINT ["bash", "/usr/local/bin/run-non-root-wrapper"]
CMD ["/bin/bash"]