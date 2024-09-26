FROM docker.io/library/debian:bookworm-slim AS builder
# see also https://github.com/creemama/docker-run-non-root

ARG SUEXEC_REV=dddd1567b7c76365e1e0aac561287975020a8fad

# Install su-exec (https://github.com/ncopa/su-exec/commit/dddd1567b7c76365e1e0aac561287975020a8fad).
ADD https://github.com/ncopa/su-exec/archive/${SUEXEC_REV}.zip su-exec.zip
RUN apt update \
    && apt install --no-install-recommends -y \
        tcc \
        libc-dev \
        make \
        unzip \
    && rm -rf /var/lib/{apt,dpkg,cache,log}/ \
    && unzip su-exec.zip \
    && make -C su-exec-${SUEXEC_REV} CC=tcc \
    && mv su-exec-${SUEXEC_REV}/su-exec /usr/local/bin

# Install run-non-root.
ADD https://raw.githubusercontent.com/creemama/run-non-root/v1.5.1/run-non-root.sh /usr/local/bin/run-non-root
RUN chmod +rx /usr/local/bin/run-non-root

ADD run-non-root-wrapper.sh /usr/local/bin/docker-entrypoint.sh
RUN chmod +rx /usr/local/bin/docker-entrypoint.sh

FROM docker.io/library/debian:bookworm-slim

RUN apt update \
    && apt install -y \
        tini \
    && rm -rf /var/lib/{apt,dpkg,cache,log}/

COPY --from=builder \
    /usr/local/bin/docker-entrypoint.sh \
    /usr/local/bin/run-non-root \
    /usr/local/bin/su-exec \
    /usr/local/bin

RUN mkdir -p /home/nonroot_fallback \
    && chmod 777 /home/nonroot_fallback

VOLUME "/app"
WORKDIR "/app"

ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
CMD ["/bin/bash"]
