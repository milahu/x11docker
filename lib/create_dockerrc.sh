create_dockerrc() {             ### create dockerrc: This script runs as root (or member of group docker) on host. Also creates containerrc
  # create containerrc -> runs as unprivileged user in container
  # check and set up cgroup on host for systemd or elogind
  # run docker
  local Line= Wantcgroup= Path= Ungrep= 

  echo "#! /usr/bin/env bash"
  echo ""
  echo "# dockerrc:"
  echo "#  This script runs as root (or member of group docker) on host."
  echo "#  - inspect image"
  echo "#  - pull image if needed"
  echo "#  - create containerrc"
  echo "#  - set up systemd/elogind cgroup if needed"
  echo "#  - run window manager in container or from host if needed"
  echo ""
  echo "trap '' SIGINT"
  echo ""

  declare -f askyesno
  declare -f checkpid
  declare -f escapestring
  declare -f mysleep
  declare -f parse_inspect
  declare -f pspid
  declare -f rmcr
  declare -f rocknroll
  declare -f saygoodbye
  declare -f storeinfo
  declare -f storepid
  declare -f waitforlogentry
  echo "$Messagefifofuncs"
  echo ""
  
  [ "$Winsubsystem" = "MSYS2" ] && {
    echo "# avoid path conversion in MSYS2 commands"
    echo "export MSYS2_ARG_CONV_EXCL='*'"
    echo ""
  }
  
  echo "Cachefolder='$Cachefolder'"
  echo "Containercommand=\"$Containercommand\""
  echo "Imagename=\"$Imagename\""
  echo "Messagefile='$Messagefifo'"
  echo "Newxenv='$Newxenv'"
  echo "export PATH='$PATH'"
  echo "Pythonbin='$Pythonbin'"
  echo "Storeinfofile='$Storeinfofile'"
  echo "Storepidfile='$Storepidfile'"
  echo "Timetosaygoodbyefile='$Timetosaygoodbyefile'"
  echo "Timetosaygoodbyefifo='$Timetosaygoodbyefifo'"
  echo "Xserver='$Xserver'"
  echo "Workdir='$Workdir'"
  echo ""
  echo "Containerarchitecture="
  echo "Containerid="
  echo "Containerip="
  echo "Dockerlogspid=''"
  echo "Exec="
  echo "Entrypoint="
  echo "Failure="
  echo "Imagepull="
  echo "Imageuser="
  echo "Inspect="
  echo "Line="
  echo "Pid1pid="
  echo "Runtime="
  echo "Signal="
  
  echo "debugnote 'Running dockerrc: Setup as root or as user docker on host.'"
  [ "$Debugmode" = "yes" ] && {
    echo "PS4='+ dockerrc: \$(date +%S+%3N) '"
    #echo "set -x"
    #declare -f traperror | sed 's/Command/dockerrc: Command/'
    echo "traperror() {                   # trap ERR: --debug: Output for 'set -o errtrace'"
    echo '  debugnote "dockerrc: Command at Line ${2:-} returned with error code ${1:-}:
  ${4:-}
  ${3:-} - ${5:-}"'
    echo "  saygoodbye dockerrc-traperror"
    echo "  exit 64"
    echo "}"
    echo "set -Eu"
    echo "trap 'traperror \$? \$LINENO \$BASH_LINENO \"\$BASH_COMMAND\" \$(printf \"::%s\" \${FUNCNAME[@]})'  ERR"
  }
  echo ""

  # transfer DOCKER_* environment variables, e.g. DOCKER_HOST.
  # can get lost e.g. if using --pw=sudo or --pw=pkexec
  while read Line; do
    debugnote "dockerrc:  Found docker environment variable: $Line"
    echo "export '$Line'"
  done < <(env | grep -e '^DOCKER_' ||:)
  echo ""

  echo "# Check whether docker daemon is running, get docker info"
  ### FIXME regard rootless docker
  echo "$Containerbackendbin info >>$Dockerinfofile 2>>$Containerlogfile  || {
  error \"'$Containerbackend info' failed.
  If using docker: Is docker daemon running at all?
  Try to start docker daemon with 'systemctl start docker'.
  Last lines of log:
\$(rmcr < '$Containerlogfile' | tail)\"
}