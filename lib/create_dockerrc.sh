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
}"
  echo ""

  
  echo "# Check default runtime"
  echo "Runtime=\"\$( { grep 'Default Runtime' < '$Dockerinfofile' ||: ;} | awk '{print \$3}' )\""
  echo '[ -n "$Runtime" ] && {' 
  echo "  debugnote \"dockerrc: Found default container Runtime: \$Runtime\""
  echo "  debugnote \"dockerrc: All \$(grep 'Runtimes' < '$Dockerinfofile' ||: )\""
  echo "  [ \"\$Runtime\" != '$Runtime' ] && {"
  echo "    case \$Runtime in"
  echo "      kata-runtime)  warning 'Found default container runtime kata-runtime.
  Please run x11docker with --runtime=kata-runtime to avoid issues.' ;;"
  echo "      nvidia) [ '$Sharegpu' = 'yes' ] &&  warning 'Option --gpu: Found default container runtime nvidia.
  Please run x11docker with --runtime=nvidia to avoid issues.' ;;"
  echo "      runc|crun|oci) ;;"
  echo "      *) note \"Found unknown container runtime: \$Runtime
  Please report at:  https://github.com/mviereck/x11docker\" ;;"
  echo "    esac"
  echo "  }"
  echo "}"
  echo "Runtime='${Runtime:-UNDECLARED_RUNTIME}'"
  echo "debugnote \"dockerrc: Container Runtime: \$Runtime\""
  echo "storeinfo \"runtime=\$Runtime\""
  echo ""
  
  echo "# Refresh images.list for x11docker-gui" ### FIXME makes no sense with multiple backends. But list needed below.
  echo "$Containerbackendbin images 2>>$Containerlogfile | grep -v REPOSITORY | awk '{print \$1 \":\" \$2}' >>$Dockerimagelistfile.sort"
  echo "rmcr $Dockerimagelistfile.sort"
  echo "while read -r Line ; do"
  echo '  grep -q "<none>" <<<$Line || echo $Line >> '$Dockerimagelistfile
  echo "done < <(sort < $Dockerimagelistfile.sort)"
  echo "rm $Dockerimagelistfile.sort"
  echo ""

  echo "# Check if image $Imagename is available locally"
  echo "Imagepull=no"
  case $Pullimage in
    no) ;;
    always) echo "Imagepull=yes" ;;
#    yes) echo "$Containerbackendbin inspect $Imagename >>$Containerlogfile 2>&1 || Imagepull=yes" ;;
    yes) echo "$Containerbackendbin images | grep -q '^$Imagename ' || Imagepull=yes" ;;
    ask)
      [ "$Runsinterminal" = "yes" ] && {
        echo "grep -x -q '$Imagename' < $Dockerimagelistfile || grep -x -q '$Imagename:latest' < $Dockerimagelistfile || {"
        echo "  $Containerbackendbin images | grep -q '^$Imagename ' || {"
        echo "    echo $Imagename | grep -q 'x11docker/' && echo 'You can build images from x11docker repository with e.g.:
  x11docker --build $Imagename
'"
        echo "    echo 'Image $Imagename not found locally.' >&2"
        echo "    echo 'Do you want to pull it from docker hub?' >&2"
        echo "    askyesno && Imagepull=yes || error \"Image '$Imagename' not available locally and not pulled from docker hub.\""
        echo "  }"
        echo "}"
      }
    ;;
  esac
  echo ""
  
  echo "rocknroll || exit 64"
  echo ""

  echo "[ \"\$Imagepull\" = 'yes' ] && {"
  echo "  note \"Pulling image '$Imagename' from docker hub\""
  [ "$Runsinterminal" = "no" ] && case $Passwordneeded in
    no)  echo "  env DISPLAY='$Hostdisplay' DBUS_SESSION_BUS_ADDRESS='${DBUS_SESSION_BUS_ADDRESS:-}' bash           -c \"notify-send 'x11docker: Pulling image $Imagename'\" 2>/dev/null &" ;;
    yes) echo "  env DISPLAY='$Hostdisplay' DBUS_SESSION_BUS_ADDRESS='${DBUS_SESSION_BUS_ADDRESS:-}' su '$Hostuser' -c \"notify-send 'x11docker: Pulling image $Imagename'\" 2>/dev/null &" ;;
  esac
  echo "  $Sudo $Containerbackendbin pull $Imagename 1>&2 || error \"Pulling image '$Imagename' seems to have failed!\""
  echo "}"
  echo ""

  echo "rocknroll || exit 64"
  echo ""

  echo "Inspect=\"\$($Containerbackendbin inspect $Imagename)\""
  
  echo "# Check architecture"
  echo 'Containerarchitecture=$(parse_inspect "$Inspect" "Architecture")'
  echo "debugnote \"dockerrc: Image architecture: \$Containerarchitecture\""
  
  echo "# Check CMD"
  echo "[ -z \"\$Containercommand\" ] && {"
  echo "  # extract image command from image if not given on cli"
  echo '  Containercommand="$(parse_inspect "$Inspect" "Config" "Cmd")"'
  echo "  debugnote \"dockerrc: Image CMD: \$Containercommand\""
  echo "  echo \"\$Containercommand\" | grep -q $(convertpath share $Containerrc) && error 'Recursion error: Found CMD $(convertpath share $Containerrc) in image.
  Did you use 'docker commit' with an x11docker container?
  Please build new images with a Dockerfile instead of using docker commit,
  or provide a different container command.'"
  echo "}"
  echo ""
  
  
  echo "# Check USER"
  echo 'Imageuser="$(parse_inspect "$Inspect" "Config" "User")"'
  echo "debugnote \"dockerrc: Image USER: \$Imageuser\""
  case $Createcontaineruser in
    yes)
      echo "[ \"\$Imageuser\" ] && note \"Found 'USER \$Imageuser' in image."
      echo "  If you want to run with user \$Imageuser instead of host user $Containeruser,"
      echo "  than run with --user=RETAIN.\""
      echo "storeinfo containeruser=\"$Containeruser\""
    ;;
    no)
      echo 'storeinfo containeruser="${Imageuser:-root}"'
    ;;
  esac
  echo ""
  
  case $Noentrypoint in
    yes) echo "Entrypoint=" ;;
    no)
      echo     "# Check ENTRYPOINT"
      echo     'Entrypoint="$(parse_inspect "$Inspect" "Config" "Entrypoint")"'
      echo     "debugnote \"dockerrc: Image ENTRYPOINT: \$Entrypoint\""
      case $Initsystem in
        systemd|sysvinit|runit|openrc|tini)
          echo "echo \"\$Entrypoint\" | grep -qE 'tini|init|systemd' && {"
          echo "  note \"There seems to be an init system in ENTRYPOINT of image:
    \$Entrypoint
  Will disable it as x11docker already runs an init with option --$Initsystem.
  To allow this ENTRYPOINT, run x11docker with option --init=none.\""
          echo "  Entrypoint="
          echo "}"
          #echo "Exec=exec"
        ;;
        s6-overlay)
          echo "[ \"\$Entrypoint\" = '/init' ] && {"
          echo "  Entrypoint="
          echo "  [ \"\$Containercommand\" ] || Containercommand=\"sh -c 'while :; do sleep 10; done'\""
          echo "}"
        ;;
        none)
          echo "echo \"\$Entrypoint\" | grep -qE 'tini|init|systemd' && {"
          echo "  note \"There seems to be an init system in ENTRYPOINT of image:
  \$Entrypoint 
  Returning exit code of container command will fail.\""
          echo "  Exec=exec"
          echo "}"
        ;;
      esac
    ;;
  esac
  echo ""
  
  [ -z "$Workdir" ] && {
    echo "# Check WORKDIR"
    echo 'Workdir="$(parse_inspect "$Inspect" "Config" "Workdir")"'
    echo "debugnote \"dockerrc: Image WORKDIR: \$Workdir\""
    echo "[ \"\$Workdir\" ] && note \"Found 'WORKDIR \$Workdir' in image. 
  You can change it with option --workdir=DIR.\""
    echo ""
  }
  
  case "$Containersetup" in
    no) ;;
    yes)      
      echo "[ -z \"\$Containercommand\$Entrypoint\" ] && error 'No container command specified and no CMD or ENTRYPOINT found in image.'"
      echo ""
     
      echo     "######## Create $(basename $Containerrc) ########"
      echo     ""
      echo     "{ echo '#! /bin/sh'"
      #[ "$Debugmode" = "yes" ] && echo "echo 'set -x'"
      echo     "  echo ''"
      echo     "  echo '# $(basename $Containerrc)'"
      echo     "  echo '# Created startscript for docker run used as container command.'"
      echo     "  echo '# Runs as unprivileged user in container.'"
      echo     "  echo ''"
     
      [ "$Interactive" = "no" ] && {
        echo   "  echo 'exec >>$(convertpath share $Containerlogfile) 2>&1'"
      }
      echo     "  echo ''"
     
      echo     "  echo '$(declare -f mysleep)'"
      echo     "  echo '$(declare -f rocknroll)'"
      echo     "  echo '$(declare -f saygoodbye)'"
      echo     "  echo '$(declare -f storeinfo)'"
      echo     "  echo '$(declare -f waitforlogentry)'"
      echo     "  echo '$Messagefifofuncs'"
      echo     "  echo 'Messagefile=$(convertpath share $Messagefifo)'"
      echo     "  echo 'Storeinfofile=$(convertpath share $Storeinfofile)'"
      echo     "  echo 'Timetosaygoodbyefile=$(convertpath share $Timetosaygoodbyefile)'"
      echo     "  echo ''"
      
      echo     "  echo 'waitforlogentry $(basename $Containerrc) \$Storeinfofile containerrootrc=ready "" infinity'"
     
      echo     "  echo 'debugnote \"Running $(basename $Containerrc): Unprivileged user commands in container\"'"
      echo     "  echo ''"
     
      echo     '  echo "Containercommand=\"$Containercommand\""'
      echo     '  echo "Entrypoint=\"$Entrypoint\""'
      echo     "  echo ''"
      echo     "  echo 'verbose \"$(basename $Containerrc): Container system:'"
      echo     "  echo '\$(cat /etc/os-release 2>&1 ||:)\"'"
      echo     "  echo ''"
     
      echo     "} >> $Containerrc"
     
      [ "$Switchcontaineruser" = "yes" ] && {   ### FIXME try --format '{{json .ContainerConfig.Env}}'
        echo "echo '# Environment variables found in image:'   >> $Containerrc"
        echo "IFS=$'\n'"
        echo "while read -r Line; do"
        echo "  echo \"export \$(escapestring \"\$Line\")\"  >> $Containerrc"
        echo "done < <($Containerbackendbin run --rm --entrypoint env $Imagename env 2>>$Containerlogfile | rmcr | grep -v 'HOSTNAME=' )"
        echo "IFS=$' \t\n'"
      }
     
      echo     "{"
      echo     "  echo ''"
      echo     "  echo '# USER and HOME'"
      echo     "  echo 'Containeruser=\"\$(storeinfo dump containeruser)\"'"
      case $Createcontaineruser in
        yes)
          echo "  echo 'Containeruserhome=\"$Containeruserhome\"'"
        ;;
        no)
          case $Sharehome in
            no)
              echo "  echo 'Containeruserhome=\"\$(cat /etc/passwd | grep \"\$Containeruser:.:\" | cut -d: -f6)\"'"
              echo "  echo 'Containeruserhome=\"\${Containeruserhome:-/tmp/\$Containeruser}\"'"
              echo "  echo 'mkdir -p \"\$Containeruserhome\"'"
            ;;
            volume)
              echo "  echo 'Containeruserhome=\"$Containeruserhome\"'"    
            ;;
          esac
        ;;
      esac
      echo     "  echo 'export USER=\"\$Containeruser\"'"
      echo     "  echo '[ \"\$Containeruserhome\" ] && {'"
      echo     "  echo '  export HOME=\"\$Containeruserhome\"'"
      echo     "  echo '}'"
      echo     "  echo ''"
  
      echo     "  echo '# XDG_RUNTIME_DIR'"
      echo     "  echo 'Containeruseruid=\$(id -u \$Containeruser)'"
      echo     "  echo 'export XDG_RUNTIME_DIR=/tmp/XDG_RUNTIME_DIR'"
      echo     "  echo '[ -e /run/user/\$Containeruseruid ] && ln -s /run/user/\$Containeruseruid \$XDG_RUNTIME_DIR || mkdir -p -m700 \$XDG_RUNTIME_DIR'"
      echo     "  echo ''"
      
      # softlinks from shared folders to HOME
      [ "$Persistanthomevolume" != "$Containeruserhosthome" ] && { # not for --home=$HOME
        while read -r Line; do
          Path="$(convertpath container "$Line")"
          [ "$(cut -c1-5 <<< "$Line")" != "/dev/" ] && {
            [ "$Line" != "$Path" ] && {   # different for paths in HOME without --home
              case $Line in
                "$Containeruserhosthome") # --share=$HOME
                  echo "  echo 'ln -s \"$Path\" -T \"$Containeruserhome/home.host.$Containeruser\"'"                
                  Ungrep="$Ungrep|home.host.$Containeruser"
                ;;
                *)
                  echo "  echo 'mkdir -p $(dirname "$Line")'"
                  echo "  echo 'ln -s \"$Path\" -T \"$(dirname "$Line")\"'"
                  Ungrep="$Ungrep|$(basename "$Line")"
                ;;
              esac
            }
          }
        done < <(store_runoption dump volume)
      }
  
      echo     "  echo '# Copy files from /etc/skel into empty HOME'"
      echo     "  echo '[ -d \"\$HOME\" ] && {'"
      echo     "  echo '  [ -d /etc/skel ] && [ -z \"\$(ls -A \"\$Containeruserhome\" 2>/dev/null | grep -v -E \"gnupg$Ungrep\")\" ] && {'"
      echo     "  echo '    debugnote \"$(basename $Containerrc): HOME is empty. Copying from /etc/skel\"'"
      echo     "  echo '    cp -n -R /etc/skel/. \$Containeruserhome'"
      echo     "  echo '    :'"
      echo     "  echo '  } || {'"
      echo     "  echo '    debugnote \"$(basename $Containerrc): HOME is not empty. Not copying from /etc/skel\"'"
      echo     "  echo '  }'"
      echo     "  echo '}'"
      echo     "  echo ''"

      [ -n "$Newdisplay" ] && {
        echo   "  echo '# Create softlink to X unix socket'"
        echo   "  echo '[ -e /tmp/.X11-unix/X$Newdisplaynumber ] || ln -s /X$Newdisplaynumber /tmp/.X11-unix'"
        echo   "  echo ''"
      }
  
      [ "$Dbusrunsession" = "yes" ]  && {
        echo   "  echo '# Check for dbus user daemon command'"
        echo   "  echo 'command -v dbus-run-session >/dev/null && Dbus=dbus-run-session || note \"Option --dbus: dbus seems to be not installed.
  Cannot run a DBus user session. Please install package dbus in image.\"'"
        echo   "  echo ''"
      }
  
      case $Xserver in
        --tty)
          echo "  echo 'unset DISPLAY WAYLAND_DISPLAY XAUTHORITY'" ;;
        --weston|--kwin|--hostwayland)
          echo "  echo 'unset DISPLAY XAUTHORITY'" ;;
        *)
          echo "  echo 'unset WAYLAND_DISPLAY'" ;;
      esac
      echo     "  echo ''"
      [ "$Setupwayland" = "yes" ] && {
        echo   "  echo '# Wayland environment'"
        echo   "  echo 'export WAYLAND_DISPLAY=$Newwaylandsocket'"
        echo   "  echo 'ln -s /$Newwaylandsocket \$XDG_RUNTIME_DIR/$Newwaylandsocket'"
      } || {
        echo   "  echo 'export XDG_SESSION_TYPE=x11'"
      }
      echo     "  echo ''"

      echo     "  echo ''"
      echo     "  echo 'export TERM=xterm'"

      echo     "  echo 'storeinfo test locale && export LANG=\"\$(storeinfo dump locale)\"'"

      echo     "  echo '[ -e \"$Hostlocaltimefile\" ] || export TZ=$Hostutctime'"
      echo     "  echo '[ \"\$(date -Ihours)\" != \"$(date -Ihours)\" ] && export TZ=$Hostutctime'"

      echo     "  echo '[ \"\$DEBIAN_FRONTEND\" = noninteractive ] && unset DEBIAN_FRONTEND && export DEBIAN_FRONTEND'"
      echo     "  echo '[ \"\$DEBIAN_FRONTEND\" = newt ]           && unset DEBIAN_FRONTEND && export DEBIAN_FRONTEND'"

      echo     "  echo '# container environment (--env)'"
      while read -r Line ; do  ### FIXME '\\\' not transmitted
        echo   "  echo \"export '$Line'\""
#        echo "$Line" >&2
#        echo   "  echo \"export $(escapestring "$Line")\""
#        echo   "  echo \"export $(escapestring "$Line")\"" >&2
#        echo   "  echo \"export \\\"$(escapestring "$Line")\\\"\"" >&2
#        echo   "  echo \"export \\\"$(escapestring "$Line")\\\"\""
      done < <(store_runoption dump env)
      echo     "  echo ''"

      [ "$Xauthentication" = "yes" ] || echo "  echo 'unset XAUTHORITY && export XAUTHORITY'"

      echo     "  echo '[ -d \"\$HOME\" ] && cd \"\$HOME\"'"
      echo     '  [ "$Workdir" ] && echo "[ -d \"$Workdir\" ] && cd \"$Workdir\"    # WORKDIR in image"'
      echo     "  echo ''"
      echo     "  echo ''"

      echo     "  echo 'env >> $(convertpath share $Containerenvironmentfile)'"
      echo     "  echo 'verbose \"Container environment:'"
      echo     "  echo '\$(env | sort)\"'"
      echo     "  echo ''"
  
      [ "$Initsystem" = "systemd" ] && {
        echo   "  echo 'systemctl --user start  dbus'"
        echo   "  echo ''"
      }
  
      case $Interactive in
        no)
          echo "  echo 'tail -f $(convertpath share $Cmdstdoutlogfile)     2>/dev/null &'"
          echo "  echo 'tail -f $(convertpath share $Cmdstderrlogfile) >&2 2>/dev/null &'"
          echo "  echo \"exec \\\$Dbus sh $(convertpath share $Cmdrc) >>$(convertpath share $Cmdstdoutlogfile) 2>>$(convertpath share $Cmdstderrlogfile)\""
        ;;
        yes)
          echo "  echo \"\$Exec \\\$Dbus \$Entrypoint \$Containercommand\" <&0"
        ;;
      esac
      echo     "} >> $Containerrc"
      echo     "######## End of containerrc ########"
      echo ""
  
      echo "# Write containerrc into x11docker.log"
      echo "nl -ba >> $Logfile < $Containerrc"
      echo ""
      echo     "######## Create $(basename $Cmdrc) ########"
      echo     "{ echo '#! /bin/sh'"
      echo     "  echo '# Created startscript for cmdrc containing final container command'"
      echo     "  echo ''"
      echo     "  echo '$(declare -f storeinfo)'"
      echo     "  echo '$Messagefifofuncs'"
      echo     "  echo 'Messagefile=$(convertpath share $Messagefifo)'"
      echo     "  echo 'Storeinfofile=\"$(convertpath share $Storeinfofile)\"'"
      echo     "  echo ''"
      # --runasuser commands added here
      [ "$Runasuser" ] && {
        echo   "  echo '# Custom daemon commands added with option --runasuser'"
        for Line in "$Runasuser"; do
        echo   "  echo 'debugnote \"$(basename $Cmdrc): Adding command:
  $Line\"'"
          echo "  echo '$Line'"
        done
        echo   "  echo ''"
      }
      echo     "  echo \"debugnote \\\"$(basename $Cmdrc): Running container command: 
  \$Entrypoint \$Containercommand
  \\\"\""
      echo     "  echo ''"
      echo     "  echo \"\$Entrypoint \$Containercommand $( [ "$Forwardstdin" = "yes" ] && echo "<$(convertpath share $Cmdstdinfifo)" ) \""
      echo     "  echo \"storeinfo cmdexitcode=\\\$?\""
      echo     "  echo ''"
      echo     "  echo '[ -h \"\$Homesoftlink\" ] && rm \$Homesoftlink'"
      echo     "} >> $Cmdrc"
      echo     "######## End of cmdrc ########"
      echo ""
  
      echo "# Write cmdrc into x11docker.log"
      echo "nl -ba >> $Logfile < $Cmdrc"
      echo ""


      # check [and create] cgroup mountpoint for systemd or elogind
      [ "$Sharecgroup" = "yes" ] && [ "$Dbussystem" = "yes" ] && {
        [ "$Initsystem" = "systemd" ] && Wantcgroup=systemd || Wantcgroup=elogind
        findmnt /sys/fs/cgroup/$Wantcgroup >/dev/null || {
          echo   "# Check [and create] cgroup mountpoint for $Wantcgroup"
          echo   "[ '$Wantcgroup' = 'systemd' ] || $Containerbackendbin run --rm --entrypoint env $Imagename sh -c 'ls /lib/elogind/elogind || ls /usr/sbin/elogind|| ls /usr/libexec/elogind' && {"
          echo   '  [ "$(id -u)"  = "0" ] && note "Creating cgroup mountpoint for '$Wantcgroup'."'
          echo   '  [ "$(id -u)" != "0" ] && {'
          echo   "    note 'Want to create and mount a cgroup for $Wantcgroup.
  As x11docker currently does not run as root, this will probably fail.
  Please either run x11docker as root, or run with option --pw=su or --pw=sudo.
    
  Alternatively, create cgroup mountpoint yourself with:
    mkdir -p /sys/fs/cgroup/$Wantcgroup
    mount -t cgroup cgroup /sys/fs/cgroup/$Wantcgroup -o none,name=$Wantcgroup
    
  If you get a read-only error message, remove write protection with:
    mount -o remount,rw cgroup /sys/fs/cgroup
    
  You can restore write protection after cgroup creation with:
    mount -o remount,ro cgroup /sys/fs/cgroup'"
          [ "$Wantcgroup" = "elogind" ] && echo "note 'If you do not want or need elogind in container,
  just ignore message above.'"
          echo   "  }"
          findmnt /sys/fs/cgroup -O ro >/dev/null && {
            echo "  mount -o remount,rw cgroup /sys/fs/cgroup >>$Containerlogfile 2>&1"
            echo "  Remounted=yes"
          }
          echo   "  mkdir -p /sys/fs/cgroup/elogind >>$Containerlogfile 2>&1"
          echo   "  mount -t cgroup cgroup /sys/fs/cgroup/elogind -o none,name=elogind  >>$Containerlogfile 2>&1"
          echo   '  [ "${Remounted:-}" = "yes" ] && mount -o remount,ro cgroup /sys/fs/cgroup  >>'$Containerlogfile' 2>&1'
          echo   "}"
          echo   ""
        }
      }
  
    ;;
  esac
  
  echo "# Send signal to run X and wait for X to be ready"
  echo 'storeinfo readyforX=ready'
  echo "waitforlogentry 'dockerrc' $Xinitlogfile 'xinitrc is ready' '$Xiniterrorcodes'"
  echo ""
  
  echo "rocknroll || exit 64"
  echo ""
  
  echo "#### run docker image ####"
#      echo "$Dockercommand "
  case $Interactive in
    no)  
      echo "read Containerid < <($Dockercommand 2>>$Containerlogfile | rmcr)"
#      echo "read Containerid < <($Dockercommand | rmcr)" 
    ;;
    yes)
      #echo "docker run --rm -ti alpine sh <&0 &"
      [ "$Winpty" ] && echo "$Winpty bash $Dockercommandfile <&0 &" || echo "$Dockercommand <&0 &"
      echo "Containerid=$Containername"
    ;;
  esac
  echo "##########################"
  echo ""
  echo ""

  echo "[ \"\$Containerid\" ] || {
    error \"Startup of $Containerbackend failed. Did not receive a container ID.
    
  Last lines of container log:
\$(rmcr < $Containerlogfile | tail)\"
}"
  echo 'storeinfo containerid="$Containerid"'
  
  echo "# Wait for container to be ready"
  echo "for ((Count=1 ; Count<=40 ; Count++)); do"
  echo "  $Containerbackendbin exec $Containername sh -c : 2>&1 | rmcr >>$Containerlogfile && { debugnote 'dockerrc: Container is up and running.' ; break ; } || debugnote \"dockerrc: Container not ready on \$Count. attempt, trying again.\""
  echo "  rocknroll || exit 64"
  echo "  mysleep 0.1"
  echo "done"
  echo ""
  
  [ "$Containersetup" = "no" ] && {
#    echo "$Containerbackendbin logs -f \$Containerid >> $Containerlogfile 2>&1 &"
    echo "# Store container output separated for stdout and stderr"
    echo "$Containerbackendbin logs -f \$Containerid 1>>$Cmdstdoutlogfile 2>>$Cmdstderrlogfile &"
    echo "Dockerlogspid=\$!"
    echo "storepid \$Dockerlogspid dockerlogs"  
    echo ""
  }

  echo "# Wait for pid 1 in container"
  echo "for ((Count=1 ; Count<=40 ; Count++)); do"
  echo "  Inspect=\"\$($Containerbackendbin inspect $Containername 2>>$Containerlogfile | rmcr)\""
  echo '  [ "$Inspect" != "[]" ] && Pid1pid="$(parse_inspect "$Inspect" "State" "Pid")"'
  echo "  debugnote \"dockerrc: \$Count. check for PID 1: \$Pid1pid\""
    case $Mobyvm in
      no)  echo '  checkpid "$Pid1pid" && break' ;;
      yes) echo '  [ "$Pid1pid" ] && [ "$Pid1pid" != "0" ] && break' ;;
    esac
  echo "  rocknroll || exit 64"
  echo "  mysleep 0.1"
  echo "done"
  echo '[ "$Pid1pid" = "0" ] && Pid1pid=""'

  echo '[ -z "$Pid1pid" ] && error "dockerrc(): Did not receive PID of PID1 in container.
  Maybe the container immediately stopped for unknown reasons.
  Just in case, check if host and image architecture are compatible:
  Host architecture: '$Hostarchitecture', image architecture: $Containerarchitecture.
  Output of \"'$Containerbackend' ps | grep x11docker\":
$('$Containerbackendbin' ps | grep x11docker)
  
  Content of container log:
$(rmcr < '$Containerlogfile' | uniq )"'
  echo 'storeinfo pid1pid="$Pid1pid"'
  echo ""

  echo "# Get IP of container"
  echo 'Containerip="$(parse_inspect "$Inspect" "NetworkSettings" "IPAddress")"'
  echo 'storeinfo containerip=$Containerip'
  echo ""
  
  echo "# Check log for startup failure"
  echo "Failure=\"\$(rmcr < $Containerlogfile | grep -v grep | grep -E 'Error response from daemon|OCI runtime exec' ||:)\""
  echo "[ \"\$Failure\" ] && {"
  echo "  echo \"\$Failure\" >>$Containerlogfile"
  echo "  error \"Got error message from $Containerbackend:
\$Failure

  Last lines of logfile:
\$(tail $Containerlogfile)\""
  echo "}"
  echo ""
  
  [ "$Switchcontaineruser" = "no" ] && [ "$Containersetup" = "yes" ] && {
    echo "debugnote 'dockerrc(): Starting containerrootrc with docker exec'"
    echo "# copy containerrootrc inside of container to avoid possible noexec of host home."
    echo "$Containerbackendbin exec $Containername sh -c 'cp $(convertpath share $Containerrootrc) /tmp/containerrootrc ; chmod 644 /tmp/containerrootrc' 2>&1 | rmcr >>$Containerlogfile"
    echo "# run container root setup. containerrc will wait until setup script is ready."
    echo "$Containerbackendbin exec -u root $Containername /bin/sh /tmp/containerrootrc 2>&1 | rmcr >>$Containerlogfile"
    echo ""
  }
  
  echo "storeinfo dockerrc=ready"
  echo ""
  
  case $Mobyvm in
    no)
      echo '[ "$Containerid" ] && {'
      echo "  # wait for signal of finish()"
      echo "  read Signal <$Dockerstopsignalfifo"
      echo '  [ "$Signal" = "stop" ] && {'
      echo "    [ \"\$Containerid\" ]   && $Containerbackendbin stop \$Containerid     >> $Containerlogfile 2>&1 &"
      echo "    [ \"\$Dockerlogspid\" ] && kill \$Dockerlogspid              >> $Containerlogfile 2>&1 &"
      echo "  }"
      echo "} & storepid \$! dockerstopshell"
    ;;
  esac
  
  echo "exit 0"
  return 0
}