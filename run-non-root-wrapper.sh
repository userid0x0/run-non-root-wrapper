#!/bin/bash
# shellcheck shell=bash

verbose() {
  ! { [ "${RUN_NON_ROOT_VERBOSE}" = "false" ] || [ "${RUN_NON_ROOT_VERBOSE}" = "0" ] || [ -z "${RUN_NON_ROOT_VERBOSE}" ] ; }
}

escape_double_quotation_marks () {
  printf "%s" "$1" | sed 's/"/\\"/g'
}

stringify_arguments () {
  # "How to use arguments like $1 $2 … in a for loop?"
  # https://unix.stackexchange.com/questions/314032/how-to-use-arguments-like-1-2-in-a-for-loop
  local command
  command="$(escape_double_quotation_marks "${1}")"
  shift
  for arg
    # "How to check if a string has spaces in Bash shell"
    # https://stackoverflow.com/questions/1473981/how-to-check-if-a-string-has-spaces-in-bash-shell
    do case "${arg}" in
      *\ *)
        command="${command} \"$(escape_double_quotation_marks "${arg}")\""
        ;;
      *)
        command="${command} $(escape_double_quotation_marks "${arg}")"
        ;;
    esac
  done
  printf "%s" "${command}"
}

main () {
  local isDocker isPodman isRoot runNonRootEnvAvailable runNonRootUidGidAvailable
  local runNonRootArgs
  isDocker=false
  isPodman=false
  isRoot=false
  runNonRootEnvAvailable=false
  runNonRootUidGidAvailable=false

  runNonRootArgs=()

  [ -f /.dockerenv ] && isDocker=true
  # shellcheck disable=SC2154
  [ "${container}" = "podman" ] && isPodman=true
  { [ "$(whoami 2> /dev/null)" = 'root' ] || [ "$(id -u)" -eq 0 ]; } && isRoot=true
  [ -n "${RUN_NON_ROOT_GID}${RUN_NON_ROOT_UID}" ] && runNonRootUidGidAvailable=true
  [ -n "${RUN_NON_ROOT_GID}${RUN_NON_ROOT_GROUP}${RUN_NON_ROOT_UID}${RUN_NON_ROOT_USER}" ] && runNonRootEnvAvailable=true

  [ -n "${RUN_NON_ROOT_COMMAND}" ] \
    && { echo "Error: RUN_NON_ROOT_COMMAND not supported. Exiting ..."; exit 1; }
  [ "${isDocker}" = "false" ] && [ "${isPodman}" = "false" ] \
    && { echo "Error: Unable do detect container runtime. Exiting ..."; exit 1; }
  [ "${runNonRootEnvAvailable}" = "true" ] && [ "${isRoot}" = "false" ] \
    && { echo "Error: Please do not mix \`docker/podman --user\` with RUN_NON_ROOT_{GID,,GROUP,UID,USER}. Exiting ..."; exit 1; }
  [ -n "${RUN_NON_ROOT_STATDIR}" ] && [ "${runNonRootUidGidAvailable}" = "true" ] \
    && { echo "Warning: ignore RUN_NON_ROOT_STATDIR as RUN_NON_ROOT_{GID,UID} is set."; }
  [ -n "${RUN_NON_ROOT_STATDIR}" ] && [ ! -d "${RUN_NON_ROOT_STATDIR}" ] \
    && { echo "Error: Path '${RUN_NON_ROOT_STATDIR}' is not a directory. Exiting ..."; exit 1; }

  # use tini
  runNonRootArgs+=( "--init" )
  if [ "${runNonRootUidGidAvailable}" = "true" ]; then
    # environment variables set
    # - no output except not all variables are set
    # - run-non-root will create user
    if [ -z "${RUN_NON_ROOT_GID}" ] \
      || [ -z "${RUN_NON_ROOT_GROUP}" ] \
      || [ -z "${RUN_NON_ROOT_UID}" ] \
      || [ -z "${RUN_NON_ROOT_USER}" ]; \
      then
      echo "Info: Not all RUN_NON_ROOT_{GID,GROUP,UID,USER} environment variables are set."
      echo "Info: RUN_NON_ROOT_GID=${RUN_NON_ROOT_GID}"
      echo "Info: RUN_NON_ROOT_GROUP=${RUN_NON_ROOT_GROUP}"
      echo "Info: RUN_NON_ROOT_UID=${RUN_NON_ROOT_UID}"
      echo "Info: RUN_NON_ROOT_USER=${RUN_NON_ROOT_USER}"
      RUN_NON_ROOT_VERBOSE="true"
    fi

    RUN_NON_ROOT_VERBOSE=${RUN_NON_ROOT_VERBOSE:-"false"}
  elif [ -n "${RUN_NON_ROOT_STATDIR}" ]; then
    runNonRootArgs+=( "--uid" "$(stat -c '%u' "${RUN_NON_ROOT_STATDIR}")" )
    runNonRootArgs+=( "--gid" "$(stat -c '%g' "${RUN_NON_ROOT_STATDIR}")" )
    RUN_NON_ROOT_VERBOSE=${RUN_NON_ROOT_VERBOSE:-"false"}
  elif [ "${isPodman}" = "true" ]; then
    # podman detected
    # - no output
    RUN_NON_ROOT_VERBOSE=${RUN_NON_ROOT_VERBOSE:-"false"}
    if [ "${isRoot}" = "true" ]; then
      # podman
      # - prevent that run-non-root creates a user
      runNonRootArgs+=( "--user" "root" "--uid" "0" )
      runNonRootArgs+=( "--group" "root" "--gid" "0" )
    fi
    # else: otherwise hope that option --userns=keep-id is set
  elif [ "${isDocker}" = "true" ] && [ "${isRoot}" = "false" ]; then
    # docker not running as root, assume option --user <uid>:<gid> was specified
    # - no output
    RUN_NON_ROOT_VERBOSE=${RUN_NON_ROOT_VERBOSE:-"false"}
  fi

  RUN_NON_ROOT_VERBOSE=${RUN_NON_ROOT_VERBOSE:-"true"}
  if ! verbose; then
    runNonRootArgs+=( "--quiet" )
  fi

  verbose && echo "exec /usr/local/bin/run-non-root ${runNonRootArgs[*]} -- " "$(stringify_arguments "${@}")"
  exec /usr/local/bin/run-non-root "${runNonRootArgs[@]}" -- "${@}"
}

main "${@}"