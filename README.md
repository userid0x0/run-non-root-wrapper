# run-non-root-wrapper

Smartly run [creema/run-non-root](https://github.com/creemama/run-non-root) with Docker/Podman.

Goal is to ensure files created by Docker/Podman in a shared volume/bind mount have the same UID/GID as for the invoking user.

## Usage
```Dockerfile
# all the standard `run-non-root` stuff

ADD https://raw.githubusercontent.com/userid0x0/run-non-root-wrapper/master/run-non-root-wrapper.sh /usr/local/bin/run-non-root-wrapper
RUN chmod +x /usr/local/bin/run-non-root-wrapper

ENTRYPOINT ["/usr/local/bin/run-non-root-wrapper", "--"]
CMD ["/bin/bash"]
```

## Environment
* `RUN_NON_ROOT_STATDIR` detect desired UID:GID from this directory
* others see [creema/run-non-root](https://github.com/creemama/run-non-root)

## Logic
* `podman run`<br>use user `root` as it's mapped to the current user on the host
* `podman run --env RUN_NON_ROOT_{UID,GID}`<br>create user with UID/GID as requested
* `podman run --user <uid>:<gid>`<br>do nothing, use user created by container runtime
* `podman run --userns=keep-id`<br>do nothing, use user created by container runtime
* `podman run --env RUN_NON_ROOT_STATDIR=<path to volume> --volume <path on host>:<path to volume>`<br>create a user and group matching the owner of `RUN_NON_ROOT_STATDIR` - with PODMAN this results normally in `root:root`
* `docker run`<br>let `run-non-root` create a user (default `non-root`)
* `docker run --env RUN_NON_ROOT_{UID,GID}`<br>create user with UID/GID as requested
* `docker run --user <uid>:<gid>`<br>do nothing, use user created by container runtime
* `docker run --env RUN_NON_ROOT_STATDIR=<path to volume> --volume <path on host>:<path to volume>`<br>create a user and group matching the owner of `RUN_NON_ROOT_STATDIR` - with DOCKER this results in `<uid on host>:<gid on host>`


Note: `run-non-root-wrapper.sh` is a wrapper, the resulting logic is spread accross `run-non-root-wrapper.sh` && `run-non-root.sh`