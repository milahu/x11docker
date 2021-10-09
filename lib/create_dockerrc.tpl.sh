#! /usr/bin/env bash

#%DEFINE__ALL__TPLCONST


# dockerrc:
#  This script runs as root (or member of group docker) on host.
#  - inspect image
#  - pull image if needed
#  - create containerrc
#  - set up systemd/elogind cgroup if needed
#  - run window manager in container or from host if needed

trap '' SIGINT

askyesno () 
{ 
    local Choice;
    read -t60 -n1 -p "(timeout after 60s assuming no) [Y|n]" Choice;
    [ "$?" = '0' ] && { 
        [[ "$Choice" == [YyJj]* ]] || [ -z "$Choice" ] && return 0
    };
    return 1
}
checkpid () 
{ 
    [ -e "/proc/${1:-NONSENSE}" ]
}
escapestring () 
{ 
    echo "${1:-}" | LC_ALL=C sed -e 's/[^a-zA-Z0-9,._+@=:/-]/\\&/g; '
}
mysleep () 
{ 
    sleep "${1:-1}" 2> /dev/null || sleep 1
}
parse_inspect () 
{ 
    local Parserscript;
    Parserscript="$Cachefolder/parse_inspect.py";
    Parserscript="#! $Pythonbin
$(cat << EOF
import json,sys

def parse_inspect(*args):
    """ 
    parse output of docker|podman|nerdctl inspect
    args:
     0: ignored
     1: string containing inspect output
     2..n: json keys. For second level keys provide e.g. "Config","Cmd"
    Prints key value as a string.
    Prints empty string if key not found.
    A list is printed as a string with '' around each element.
    """
    
    output=""
    inspect=args[1]
    inspect=inspect.strip()
    if inspect[0] == "[" :
        inspect=inspect[1:-2] # remove enclosing [ ]

    obj=json.loads(inspect)
    
    for arg in args[2:]: # recursively find the desired object. Command.Cmd is found with args "Command" , "Cmd"
        try:
            obj=obj[arg]
        except:
            obj=""
            
    objtype=str(type(obj))
    if "'list'" in objtype:
        for i in obj:
            output=output+"'"+str(i)+"' "
    else:
        output=str(obj)
    
    if output == "None":
        output=""
        
    print(output)

parse_inspect(*sys.argv)
EOF
  )";
    echo "$Parserscript" | $Pythonbin - "$@"
}
pspid () 
{ 
    LC_ALL=C ps -p "${1:-}" 2> /dev/null | grep -v 'TIME'
}
rmcr () 
{ 
    case "${1:-}" in 
        "")
            sed "s/$(printf "\r")//g"
        ;;
        *)
            sed -i "s/$(printf "\r")//g" "${1:-}"
        ;;
    esac
}
rocknroll () 
{ 
    [ -s "$Timetosaygoodbyefile" ] && return 1;
    [ -e "$Timetosaygoodbyefile" ] || return 1;
    return 0
}
saygoodbye () 
{ 
    debugnote "time to say goodbye ($*)";
    [ -e "$Timetosaygoodbyefile" ] && echo timetosaygoodbye >> $Timetosaygoodbyefile;
    [ -e "$Timetosaygoodbyefifo" ] && echo timetosaygoodbye >> $Timetosaygoodbyefifo
}
storeinfo () 
{ 
    [ -e "$Storeinfofile" ] || return 1;
    case "${1:-}" in 
        dump)
            grep "^${2:-}=" $Storeinfofile | sed "s/^${2:-}=//"
        ;;
        drop)
            sed -i "/^${2:-}=/d" $Storeinfofile
        ;;
        test)
            grep -q "^${2:-}=" $Storeinfofile
        ;;
        *)
            debugnote "storeinfo(): ${1:-}";
            grep -q "^$(echo "${1:-}" | cut -d= -f1)=" $Storeinfofile && { 
                sed -i "/^$(echo "${1:-}" | cut -d= -f1)=/d" $Storeinfofile
            };
            echo "${1:-}" >> $Storeinfofile
        ;;
    esac
}
storepid () 
{ 
    case "${1:-}" in 
        dump)
            grep -w "${2:-}" "$Storepidfile" | cut -d' ' -f1
        ;;
        test)
            grep -q -w "${2:-}" "$Storepidfile"
        ;;
        *)
            echo "${1:-NOPID}" "${2:-NONAME}" >> "$Storepidfile";
            debugnote "storepid(): Stored pid '${1:-}' of '${2:-}': $(pspid ${1:-} ||:)"
        ;;
    esac
}
waitforlogentry () 
{ 
    local Startzeit Uhrzeit Dauer Count=0 Schlaf;
    local Errorkeys="${4:-}";
    local Warten="${5:-60}";
    local Error=;
    Startzeit="$(date +%s ||:)";
    Startzeit="${Startzeit:-0}";
    [ "$Warten" = "infinity" ] && Warten=32000;
    debugnote "waitforlogentry(): ${1:-}: Waiting for logentry \"${3:-}\" in $(basename ${2:-})";
    while ! grep -q "${3:-}" < "${2:-}"; do
        Count="$(( $Count + 1 ))";
        Uhrzeit="$(date +%s ||:)";
        Uhrzeit="${Uhrzeit:-0}";
        Dauer="$(( $Uhrzeit - $Startzeit ))";
        Schlaf="$(( $Count / 10 ))";
        [ "$Schlaf" = "0" ] && Schlaf="0.5";
        mysleep "$Schlaf";
        [ "$Dauer" -gt "10" ] && debugnote "waitforlogentry(): ${1:-}: Waiting since ${Dauer}s for log entry \"${3:-}\" in $(basename ${2:-})";
        [ "$Dauer" -gt "$Warten" ] && error "waitforlogentry(): ${1:-}: Timeout waiting for entry \"${3:-}\" in $(basename ${2:-})
  Last lines of $(basename ${2:-}):
$(tail "${2:-}")";
        [ "$Errorkeys" ] && grep -i -q -E "$Errorkeys" < "${2:-}" && error "waitforlogentry(): ${1:-}: Found error message in logfile.
  Last lines of logfile $(basename ${2:-}):
$(tail "${2:-}")";
        rocknroll || { 
            debugnote "waitforlogentry(): ${1:-}: Stopped waiting for ${3:-} in $(basename ${2:-}) due to terminating signal.";
            Error=1;
            break
        };
    done;
    [ "$Error" ] && return 1;
    debugnote "waitforlogentry(): ${1:-}: Found log entry \"${3:-}\" in $(basename ${2:-}).";
    return 0
}
$TPLCONST__Messagefifofuncs__TPLCONST

Cachefolder="$TPLCONST__Cachefolder__TPLCONST"
Containercommand="$TPLCONST__Containercommand__TPLCONST"
Imagename="$TPLCONST__Imagename__TPLCONST"
Messagefile="$TPLCONST__Messagefifo__TPLCONST"
Newxenv="$TPLCONST__Newxenv__TPLCONST"
export PATH="$TPLCONST__PATH__TPLCONST"
Pythonbin="$TPLCONST__Pythonbin__TPLCONST"
Storeinfofile="$TPLCONST__Storeinfofile__TPLCONST"
Storepidfile="$TPLCONST__Storepidfile__TPLCONST"
Timetosaygoodbyefile="$TPLCONST__Timetosaygoodbyefile__TPLCONST"
Timetosaygoodbyefifo="$TPLCONST__Timetosaygoodbyefifo__TPLCONST"
Xserver="$TPLCONST__Xserver__TPLCONST"
Workdir="$TPLCONST__Workdir__TPLCONST"

Containerarchitecture=
Containerid=
Containerip=
Dockerlogspid=''
Exec=
Entrypoint=
Failure=
Imagepull=
Imageuser=
Inspect=
Line=
Pid1pid=
Runtime=
Signal=
debugnote 'Running dockerrc: Setup as root or as user docker on host.'
PS4='+ dockerrc: $(date +%S+%3N) '
traperror() {                   # trap ERR: --debug: Output for 'set -o errtrace'
  debugnote "dockerrc: Command at Line ${2:-} returned with error code ${1:-}:
  ${4:-}
  ${3:-} - ${5:-}"
  saygoodbye dockerrc-traperror
  exit 64
}
set -Eu
trap 'traperror $? $LINENO $BASH_LINENO "$BASH_COMMAND" $(printf "::%s" ${FUNCNAME[@]})'  ERR


# Check whether docker daemon is running, get docker info
$TPLCONST__Containerbackendbin__TPLCONST info >>$TPLCONST__Dockerinfofile__TPLCONST 2>>$TPLCONST__Containerlogfile__TPLCONST  || {
  error "'$TPLCONST__Containerbackend__TPLCONST info' failed.
  If using docker: Is docker daemon running at all?
  Try to start docker daemon with 'systemctl start docker'.
  Last lines of log:
$(rmcr < "$TPLCONST__Containerlogfile__TPLCONST" | tail)"
}

# Check default runtime
Runtime="$( { grep 'Default Runtime' < "$TPLCONST__Dockerinfofile__TPLCONST" ||: ;} | awk '{print $3}' )"
[ -n "$Runtime" ] && {
  debugnote "dockerrc: Found default container Runtime: $Runtime"
  debugnote "dockerrc: All $(grep 'Runtimes' < "$TPLCONST__Dockerinfofile__TPLCONST" ||: )"
  [ "$Runtime" != "$TPLCONST__Runtime__TPLCONST" ] && {
    case $Runtime in
      kata-runtime)  warning 'Found default container runtime kata-runtime.
  Please run x11docker with --runtime=kata-runtime to avoid issues.' ;;
      nvidia) [ "$TPLCONST__Sharegpu__TPLCONST" = 'yes' ] &&  warning 'Option --gpu: Found default container runtime nvidia.
  Please run x11docker with --runtime=nvidia to avoid issues.' ;;
      runc|crun|oci) ;;
      *) note "Found unknown container runtime: $Runtime
  Please report at:  https://github.com/mviereck/x11docker" ;;
    esac
  }
}
Runtime="$TPLCONST__Runtime__TPLCONST"
debugnote "dockerrc: Container Runtime: $Runtime"
storeinfo "runtime=$Runtime"

# Refresh images.list for x11docker-gui
$TPLCONST__Containerbackendbin__TPLCONST images 2>>$TPLCONST__Containerlogfile__TPLCONST | grep -v REPOSITORY | awk '{print $1 ":" $2}' >>$TPLCONST__Dockerimagelistfile__TPLCONST.sort
rmcr $TPLCONST__Dockerimagelistfile__TPLCONST.sort
while read -r Line ; do
  grep -q "<none>" <<<$Line || echo $Line >> $TPLCONST__Dockerimagelistfile__TPLCONST
done < <(sort < $TPLCONST__Dockerimagelistfile__TPLCONST.sort)
rm $TPLCONST__Dockerimagelistfile__TPLCONST.sort

# Check if image $TPLCONST__Imagename__TPLCONST is available locally
Imagepull=no

rocknroll || exit 64

[ "$Imagepull" = 'yes' ] && {
  note "Pulling image "$TPLCONST__Imagename__TPLCONST" from docker hub"
  $TPLCONST__Sudo__TPLCONST $TPLCONST__Containerbackendbin__TPLCONST pull $TPLCONST__Imagename__TPLCONST 1>&2 || error "Pulling image "$TPLCONST__Imagename__TPLCONST" seems to have failed!"
}

rocknroll || exit 64

Inspect="$($TPLCONST__Containerbackendbin__TPLCONST inspect $TPLCONST__Imagename__TPLCONST)"
# Check architecture
Containerarchitecture=$(parse_inspect "$Inspect" "Architecture")
debugnote "dockerrc: Image architecture: $Containerarchitecture"
# Check CMD
[ -z "$Containercommand" ] && {
  # extract image command from image if not given on cli
  Containercommand="$(parse_inspect "$Inspect" "Config" "Cmd")"
  debugnote "dockerrc: Image CMD: $Containercommand"
  echo "$Containercommand" | grep -q  && error 'Recursion error: Found CMD  in image.
  Did you use 'docker commit' with an x11docker container?
  Please build new images with a Dockerfile instead of using docker commit,
  or provide a different container command.'
}

# Check USER
Imageuser="$(parse_inspect "$Inspect" "Config" "User")"
debugnote "dockerrc: Image USER: $Imageuser"


[ -z "$Containercommand$Entrypoint" ] && error 'No container command specified and no CMD or ENTRYPOINT found in image.'

######## Create $TPLCONST__Containerrc__TPLCONST ########

{ echo '#! /bin/sh'
  echo ''
  echo '# $TPLCONST__Containerrc__TPLCONST'
  echo '# Created startscript for docker run used as container command.'
  echo '# Runs as unprivileged user in container.'
  echo ''
  echo ''
  echo 'mysleep () 
{ 
    sleep "${1:-1}" 2> /dev/null || sleep 1
}'
  echo 'rocknroll () 
{ 
    [ -s "$Timetosaygoodbyefile" ] && return 1;
    [ -e "$Timetosaygoodbyefile" ] || return 1;
    return 0
}'
  echo 'saygoodbye () 
{ 
    debugnote "time to say goodbye ($*)";
    [ -e "$Timetosaygoodbyefile" ] && echo timetosaygoodbye >> $Timetosaygoodbyefile;
    [ -e "$Timetosaygoodbyefifo" ] && echo timetosaygoodbye >> $Timetosaygoodbyefifo
}'
  echo 'storeinfo () 
{ 
    [ -e "$Storeinfofile" ] || return 1;
    case "${1:-}" in 
        dump)
            grep "^${2:-}=" $Storeinfofile | sed "s/^${2:-}=//"
        ;;
        drop)
            sed -i "/^${2:-}=/d" $Storeinfofile
        ;;
        test)
            grep -q "^${2:-}=" $Storeinfofile
        ;;
        *)
            debugnote "storeinfo(): ${1:-}";
            grep -q "^$(echo "${1:-}" | cut -d= -f1)=" $Storeinfofile && { 
                sed -i "/^$(echo "${1:-}" | cut -d= -f1)=/d" $Storeinfofile
            };
            echo "${1:-}" >> $Storeinfofile
        ;;
    esac
}'
  echo 'waitforlogentry () 
{ 
    local Startzeit Uhrzeit Dauer Count=0 Schlaf;
    local Errorkeys="${4:-}";
    local Warten="${5:-60}";
    local Error=;
    Startzeit="$(date +%s ||:)";
    Startzeit="${Startzeit:-0}";
    [ "$Warten" = "infinity" ] && Warten=32000;
    debugnote "waitforlogentry(): ${1:-}: Waiting for logentry \"${3:-}\" in $(basename ${2:-})";
    while ! grep -q "${3:-}" < "${2:-}"; do
        Count="$(( $Count + 1 ))";
        Uhrzeit="$(date +%s ||:)";
        Uhrzeit="${Uhrzeit:-0}";
        Dauer="$(( $Uhrzeit - $Startzeit ))";
        Schlaf="$(( $Count / 10 ))";
        [ "$Schlaf" = "0" ] && Schlaf="0.5";
        mysleep "$Schlaf";
        [ "$Dauer" -gt "10" ] && debugnote "waitforlogentry(): ${1:-}: Waiting since ${Dauer}s for log entry \"${3:-}\" in $(basename ${2:-})";
        [ "$Dauer" -gt "$Warten" ] && error "waitforlogentry(): ${1:-}: Timeout waiting for entry \"${3:-}\" in $(basename ${2:-})
  Last lines of $(basename ${2:-}):
$(tail "${2:-}")";
        [ "$Errorkeys" ] && grep -i -q -E "$Errorkeys" < "${2:-}" && error "waitforlogentry(): ${1:-}: Found error message in logfile.
  Last lines of logfile $(basename ${2:-}):
$(tail "${2:-}")";
        rocknroll || { 
            debugnote "waitforlogentry(): ${1:-}: Stopped waiting for ${3:-} in $(basename ${2:-}) due to terminating signal.";
            Error=1;
            break
        };
    done;
    [ "$Error" ] && return 1;
    debugnote "waitforlogentry(): ${1:-}: Found log entry \"${3:-}\" in $(basename ${2:-}).";
    return 0
}'
  echo "$TPLCONST__Messagefifofuncs__TPLCONST"
  echo 'Messagefile='
  echo 'Storeinfofile='
  echo 'Timetosaygoodbyefile='
  echo ''
  echo 'waitforlogentry $TPLCONST__Containerrc__TPLCONST $Storeinfofile containerrootrc=ready  infinity'
  echo 'debugnote "Running $TPLCONST__Containerrc__TPLCONST: Unprivileged user commands in container"'
  echo ''
  echo "Containercommand=\"$Containercommand\""
  echo "Entrypoint=\"$Entrypoint\""
  echo ''
  echo 'verbose "$TPLCONST__Containerrc__TPLCONST: Container system:'
  echo '$(cat /etc/os-release 2>&1 ||:)"'
  echo ''
} >> $TPLCONST__Containerrc__TPLCONST
{
  echo ''
  echo '# USER and HOME'
  echo 'Containeruser="$(storeinfo dump containeruser)"'
  echo 'export USER="$Containeruser"'
  echo '[ "$Containeruserhome" ] && {'
  echo '  export HOME="$Containeruserhome"'
  echo '}'
  echo ''
  echo '# XDG_RUNTIME_DIR'
  echo 'Containeruseruid=$(id -u $Containeruser)'
  echo 'export XDG_RUNTIME_DIR=/tmp/XDG_RUNTIME_DIR'
  echo '[ -e /run/user/$Containeruseruid ] && ln -s /run/user/$Containeruseruid $XDG_RUNTIME_DIR || mkdir -p -m700 $XDG_RUNTIME_DIR'
  echo ''
  echo 'mkdir -p .'
  echo 'ln -s "/" -T "."'
  echo '# Copy files from /etc/skel into empty HOME'
  echo '[ -d "$HOME" ] && {'
  echo '  [ -d /etc/skel ] && [ -z "$(ls -A "$Containeruserhome" 2>/dev/null | grep -v -E "gnupg|")" ] && {'
  echo '    debugnote "$TPLCONST__Containerrc__TPLCONST: HOME is empty. Copying from /etc/skel"'
  echo '    cp -n -R /etc/skel/. $Containeruserhome'
  echo '    :'
  echo '  } || {'
  echo '    debugnote "$TPLCONST__Containerrc__TPLCONST: HOME is not empty. Not copying from /etc/skel"'
  echo '  }'
  echo '}'
  echo ''
  echo '# Create softlink to X unix socket'
  echo '[ -e /tmp/.X11-unix/X$TPLCONST__Newdisplaynumber__TPLCONST ] || ln -s /X$TPLCONST__Newdisplaynumber__TPLCONST /tmp/.X11-unix'
  echo ''
  echo 'unset WAYLAND_DISPLAY'
  echo ''
  echo 'export XDG_SESSION_TYPE=x11'
  echo ''
  echo ''
  echo 'export TERM=xterm'
  echo 'storeinfo test locale && export LANG="$(storeinfo dump locale)"'
  echo '[ -e "$TPLCONST__Hostlocaltimefile__TPLCONST" ] || export TZ=$TPLCONST__Hostutctime__TPLCONST'
  echo '[ "$(date -Ihours)" != "2021-10-09T11+02:00" ] && export TZ=$TPLCONST__Hostutctime__TPLCONST'
  echo '[ "$DEBIAN_FRONTEND" = noninteractive ] && unset DEBIAN_FRONTEND && export DEBIAN_FRONTEND'
  echo '[ "$DEBIAN_FRONTEND" = newt ]           && unset DEBIAN_FRONTEND && export DEBIAN_FRONTEND'
  echo '# container environment (--env)'
  echo "export ''"
  echo ''
  echo 'unset XAUTHORITY && export XAUTHORITY'
  echo '[ -d "$HOME" ] && cd "$HOME"'
  [ "$Workdir" ] && echo "[ -d \"$Workdir\" ] && cd \"$Workdir\"    # WORKDIR in image"
  echo ''
  echo ''
  echo 'env >> '
  echo 'verbose "Container environment:'
  echo '$(env | sort)"'
  echo ''
} >> $TPLCONST__Containerrc__TPLCONST
######## End of containerrc ########

# Write containerrc into x11docker.log
nl -ba >> $TPLCONST__Logfile__TPLCONST < $TPLCONST__Containerrc__TPLCONST

######## Create $TPLCONST__Cmdrc__TPLCONST ########
{ echo '#! /bin/sh'
  echo '# Created startscript for cmdrc containing final container command'
  echo ''
  echo 'storeinfo () 
{ 
    [ -e "$Storeinfofile" ] || return 1;
    case "${1:-}" in 
        dump)
            grep "^${2:-}=" $Storeinfofile | sed "s/^${2:-}=//"
        ;;
        drop)
            sed -i "/^${2:-}=/d" $Storeinfofile
        ;;
        test)
            grep -q "^${2:-}=" $Storeinfofile
        ;;
        *)
            debugnote "storeinfo(): ${1:-}";
            grep -q "^$(echo "${1:-}" | cut -d= -f1)=" $Storeinfofile && { 
                sed -i "/^$(echo "${1:-}" | cut -d= -f1)=/d" $Storeinfofile
            };
            echo "${1:-}" >> $Storeinfofile
        ;;
    esac
}'
  echo "$TPLCONST__Messagefifofuncs__TPLCONST"
  echo 'Messagefile='
  echo 'Storeinfofile=""'
  echo ''
  echo '# Custom daemon commands added with option --runasuser'
  echo 'debugnote "$TPLCONST__Cmdrc__TPLCONST: Adding command:
  $TPLCONST__Runasuser__TPLCONST"'
  echo "$TPLCONST__Runasuser__TPLCONST"
  echo ''
  echo "debugnote \"$TPLCONST__Cmdrc__TPLCONST: Running container command: 
  $Entrypoint $Containercommand
  \""
  echo ''
  echo "$Entrypoint $Containercommand  "
  echo "storeinfo cmdexitcode=\$?"
  echo ''
  echo '[ -h "$Homesoftlink" ] && rm $Homesoftlink'
} >> $TPLCONST__Cmdrc__TPLCONST
######## End of cmdrc ########

# Write cmdrc into x11docker.log
nl -ba >> $TPLCONST__Logfile__TPLCONST < $TPLCONST__Cmdrc__TPLCONST

# Send signal to run X and wait for X to be ready
storeinfo readyforX=ready
waitforlogentry 'dockerrc' $TPLCONST__Xinitlogfile__TPLCONST 'xinitrc is ready' "$TPLCONST__Xiniterrorcodes__TPLCONST"

rocknroll || exit 64

#### run docker image ####
##########################


[ "$Containerid" ] || {
    error "Startup of $TPLCONST__Containerbackend__TPLCONST failed. Did not receive a container ID.
    
  Last lines of container log:
$(rmcr < $TPLCONST__Containerlogfile__TPLCONST | tail)"
}
storeinfo containerid="$Containerid"
# Wait for container to be ready
for ((Count=1 ; Count<=40 ; Count++)); do
  $TPLCONST__Containerbackendbin__TPLCONST exec $TPLCONST__Containername__TPLCONST sh -c : 2>&1 | rmcr >>$TPLCONST__Containerlogfile__TPLCONST && { debugnote 'dockerrc: Container is up and running.' ; break ; } || debugnote "dockerrc: Container not ready on $Count. attempt, trying again."
  rocknroll || exit 64
  mysleep 0.1
done

# Wait for pid 1 in container
for ((Count=1 ; Count<=40 ; Count++)); do
  Inspect="$($TPLCONST__Containerbackendbin__TPLCONST inspect $TPLCONST__Containername__TPLCONST 2>>$TPLCONST__Containerlogfile__TPLCONST | rmcr)"
  [ "$Inspect" != "[]" ] && Pid1pid="$(parse_inspect "$Inspect" "State" "Pid")"
  debugnote "dockerrc: $Count. check for PID 1: $Pid1pid"
  rocknroll || exit 64
  mysleep 0.1
done
[ "$Pid1pid" = "0" ] && Pid1pid=""
[ -z "$Pid1pid" ] && error "dockerrc(): Did not receive PID of PID1 in container.
  Maybe the container immediately stopped for unknown reasons.
  Just in case, check if host and image architecture are compatible:
  Host architecture: $TPLCONST__Hostarchitecture__TPLCONST, image architecture: $Containerarchitecture.
  Output of \"$TPLCONST__Containerbackend__TPLCONST ps | grep x11docker\":
$($TPLCONST__Containerbackendbin__TPLCONST ps | grep x11docker)
  
  Content of container log:
$(rmcr < $TPLCONST__Containerlogfile__TPLCONST | uniq )"
storeinfo pid1pid="$Pid1pid"

# Get IP of container
Containerip="$(parse_inspect "$Inspect" "NetworkSettings" "IPAddress")"
storeinfo containerip=$Containerip

# Check log for startup failure
Failure="$(rmcr < $TPLCONST__Containerlogfile__TPLCONST | grep -v grep | grep -E 'Error response from daemon|OCI runtime exec' ||:)"
[ "$Failure" ] && {
  echo "$Failure" >>$TPLCONST__Containerlogfile__TPLCONST
  error "Got error message from $TPLCONST__Containerbackend__TPLCONST:
$Failure

  Last lines of logfile:
$(tail $TPLCONST__Containerlogfile__TPLCONST)"
}

storeinfo dockerrc=ready

exit 0
