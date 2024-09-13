# run-non-root-wrapper

Smartly run [creema/run-non-root](https://github.com/creemama/run-non-root) with Docker/Podman.

Goal is to ensure files created by Docker/Podman in a shared volume/bind mount have the same UID/GID as for the invoking user.

```Dockerfile
# all the standard `run-non-root` stuff

ADD https://raw.githubusercontent.com/userid0x0/run-non-root-wrapper/master/run-non-root-wrapper.sh /usr/local/bin/run-non-root-wrapper
RUN chmod +x /usr/local/bin/run-non-root-wrapper

ENTRYPOINT ["/usr/local/bin/run-non-root-wrapper", "--"]
CMD ["/bin/bash"]
```