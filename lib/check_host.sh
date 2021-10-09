check_host() {                  # check host environment
  local Drive

  [ "${0:-}" = "${BASH_SOURCE:-}" ] && Runssourced="no" || Runssourced="yes"

  Hostsystem="$(grep '^ID=' /etc/os-release 2>/dev/null | cut -d= -f2 || echo 'unknown')"
  Hostarchitecture="$(uname -m)"
  case "$Hostarchitecture" in
    x86_64|x86-64|amd64|AMD64)                               Hostarchitecture="amd64 ($Hostarchitecture)" ;;
    aarch64|armv8|ARMv8|arm64v8)                             Hostarchitecture="arm64v8 ($Hostarchitecture)" ;;
    aarch32|armv8l|armv7|armv7l|ARMv7|arm32v7|armhf|armv7hl) Hostarchitecture="arm32v7 ($Hostarchitecture)" ;;
    arm32v6|ARMv6|armel)                                     Hostarchitecture="arm32v6 ($Hostarchitecture)" ;;
    arm32v5|ARMv5)                                           Hostarchitecture="arm32v5 ($Hostarchitecture)" ;;
    i686|i386|x86)                                           Hostarchitecture="i386 ($Hostarchitecture)" ;;
    ppc64*|POWER8)                                           Hostarchitecture="ppc64le ($Hostarchitecture)" ;;
    s390x)                                                   Hostarchitecture="s390x ($Hostarchitecture)" ;;
    mips|mipsel)                                             Hostarchitecture="mipsel ($Hostarchitecture)" ;;
    mips64*)                                                 Hostarchitecture="mips64el ($Hostarchitecture)" ;;
    *)                                                       Hostarchitecture="unknown ($Hostarchitecture)" ;;
  esac

  # Check libc from host. If same as in container, it is possible to share timezone file
  Hostlibc="unknown"
  ldd --version 2>&1 | grep -q    'musl libc'       && Hostlibc='musl'
  ldd --version 2>&1 | grep -q -E 'GLIBC|GNU libc'  && Hostlibc='glibc'
  
  # Check host time zone
  Hostlocaltimefile="$(myrealpath /etc/localtime)"      # Find time zone file in /usr/share/zoneinfo
  [ -e "$Hostlocaltimefile" ] || Hostlocaltimefile=""
  Hostutctime=$(date +%:::z)                        # Offset of UTC. Used if time zone file cannot be provided
  [ "$(cut -c1 <<< "$Hostutctime")" = "+" ] && {
    Hostutctime="UTC-$(cut -c2- <<< "$Hostutctime")"
  } || {
    Hostutctime="UTC+$(cut -c2- <<< "$Hostutctime")"
  }
  
  # Check for MS Windows subsystem
  command -v cygcheck.exe >/dev/null && {
    cygcheck.exe -V | rmcr | grep -q "(cygwin)"   && Winsubsystem="CYGWIN"
    cygcheck.exe -V | rmcr | grep -q "(msys)"     && Winsubsystem="MSYS2"
  }
  uname -r | grep -q "Microsoft"                  && Winsubsystem="WSL1"
  uname -r | grep -q "microsoft"                  && Winsubsystem="WSL2"
  case $Winsubsystem in
    MSYS2|CYGWIN) 
      Winsubmount="$(cygpath.exe -u "c:/" | rmcr | sed s%/c/%%)"
      Winsubpath="$(convertpath unix "$(cygpath.exe -w "/" | rmcr)" )"
      Mobyvm="yes"
    ;;
    WSL1|WSL2)
      command -v "/mnt/c/Windows/System32/cmd.exe" >/dev/null && Winsubmount="/mnt"
      command -v "/c/Windows/System32/cmd.exe" >/dev/null     && Winsubmount=""
      grep -q "Windows" <<< "${PATH:-}" || export PATH="${PATH:-}:$Winsubmount/c/Windows/System32:$Winsubmount/c/Windows/System32/WindowsPowerShell/v1.0" # can miss after sudo in WSL
      command -v "$Winsubmount/c/Windows/System32/cmd.exe" >/dev/null || error "$Winsubsystem: Could not find cmd.exe 
  in /mnt/c/Windows/System32 or /c/Windows/System32.
  Do you have a different path to your Windows system partition?"
      Winsubpath="$(convertpath unix "$(getwslpath)")"
      [ "$Winsubsystem" = "WSL1" ] && Mobyvm="yes"
    ;;
  esac
  Winsubmount="${Winsubmount%/}"
  Winsubpath="${Winsubpath%/}"
  [ "$Winsubsystem" ] && Hostsystem="MSWindows-$Winsubsystem"
  
  [ -z "$Mobyvm" ] && Mobyvm="no"  
  case $Mobyvm in
    yes)
      command -v docker.exe >/dev/null || export PATH="${PATH:-}:$(convertpath subsystem "C:/Program Files/docker"):$(convertpath subsystem "C:/Program Files/Docker/Docker/resources/bin")"
      Containerbackendbin="docker.exe"
    ;;
    no)
      Containerbackendbin="$Containerbackend"
    ;;
  esac
  
  # rootful or rootless
  case $Containerbackend in
    docker)
      grep -q "/run/user/" <<< "${DOCKER_HOST:-}" && Rootlessbackend="yes"
    ;;
    podman|nerdctl|*)
      [ "$(id -u)" = "0" ] && Rootlessbackend="yes"
    ;;
  esac
  
  # Check host IP. Needed for --pulseaudio=tcp, --printer=tcp, --xoverip and --xwin
  case $Winsubsystem in
    "")
      case $Network in
        host) Hostip="127.0.0.1" ;;
        *)
          #Hostip="$(hostname -I | cut -d' ' -f1)"
          [ "$Hostip" ] || Hostip="$(ip -4 -o a | grep 'docker0' | awk '{print $4}' | cut -d/ -f1 | grep    "172.17.0.1" ||: )"
          [ "$Hostip" ] || Hostip="$(ip -4 -o a | grep 'docker0' | awk '{print $4}' | cut -d/ -f1 | head -n1)"
          [ "$Hostip" ] || Hostip="$(ip -4 -o a |                  awk '{print $4}' | cut -d/ -f1 | grep    "^192\.168\.*" | head -n1)" 
          [ "$Hostip" ] || Hostip="$(ip -4 -o a |                  awk '{print $4}' | cut -d/ -f1 | grep -v "127.0.0.1" | head -n1)" 
        ;;
      esac
    ;;
    *) 
                       Hostip="$(ipconfig.exe | rmcr | grep 'IPv4' | grep -o '192\.168\.[0-9]*\.[0-9]*'       | head -n1 )"
      [ "$Hostip" ] || Hostip="$(ipconfig.exe | rmcr | grep 'IPv4' | grep -o '10\.0\.[0-9]*\.[0-9]*'          | head -n1 )"
      [ "$Hostip" ] || Hostip="$(ipconfig.exe | rmcr | grep 'IPv4' | grep -o '[0-9]*\.[0-9]*\.[0-9]*\.[0-9]*' | head -n1 )"
    ;;
  esac
  
  # Check if docker is installed with snap/snappy
  myrealpath "$(command -v "${Containerbackendbin:-docker_not_found}")" | grep -q snap && Runsinsnap="yes" || Runsinsnap="no"
  
  # Provide dos->unix newline converter to unpriv() commands
  export -f rmcr
  
  # Check whether x11docker runs over SSH
  pstree -ps $$ >/dev/null 2>&1 && {
    pstree -ps $$ | grep -q sshd && Runsoverssh="yes" || Runsoverssh="no"
  } || {
    check_parent_sshd "$$"       && Runsoverssh="yes" || Runsoverssh="no"
  }
  
  # Check whether x11docker runs on console
  Runsonconsole="$(env LANG=C tty 2>&1)"
  case "$Runsonconsole" in
    "not a tty") Runsonconsole="" ;;
    *) 
      grep -q tty <<< "$Runsonconsole"        && Runsonconsole="yes" || Runsonconsole="no"
    ;;
  esac
  [ "$Winsubsystem"   ]                       && Runsonconsole="no"
  [ -z "$Runsonconsole" ] && {
    [ -n "${DISPLAY:-}${WAYLAND_DISPLAY:-}" ] && Runsonconsole="no"  || Runsonconsole="yes"
    debugnote "check_host(): Command tty failed. Guess if running on console: $Runsonconsole"
  }

  # Check whether x11docker runs in a terminal
  tty -s && Runsinterminal="yes" || Runsinterminal="no"
  
  # Check whether x11docker runs in interactive bash mode (--enforce-i)
  case $- in
    *i*) Runsinteractive="yes" ;;
    *)   Runsinteractive="no" ;;
  esac
  
  # Check whether ps can watch processes of other users
  mount | grep "^proc" | grep -q "hidepid=2" && {
    Hosthidepid="yes"
    debugnote "check_host(): /proc is mounted with hidepid=2."
  } || {
    Hosthidepid="no"
  }
  ps aux | cut -d' ' -f1 | grep -q root && {
    Hostcanwatchroot="yes" 
  } || {
    Hostcanwatchroot="no"
    case $Winsubsystem in
      MSYS2|CYGWIN) Hostcanwatchroot="yes" ;;
    esac
  }
  debugnote "check_host(): ps can watch root processes: $Hostcanwatchroot"
  
  # Check if host uses proprietary NVIDIA driver
  Nvidiaversion=$(head -n1 2>/dev/null </proc/driver/nvidia/version | awk '{ print $8 }')
  #Nvidiaversion="430.14"
    
  # check python version
  Pythonbin="$(command -v python)"
  [ -z "$Pythonbin" ] && Pythonbin="$(command -v python3)"
  [ -z "$Pythonbin" ] && Pythonbin="$(command -v python2)"
  [ -z "$Pythonbin" ] && error "x11docker needs 'python' to parse output of '$Containerbackend inspect'.
  This is needed to check ENTRYPOINT and CMD that in turn is needed to set up
  some x11docker features. To allow more features, please install 'python'
  version 2.x or 3.x"
  
  return 0
}