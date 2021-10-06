create_dockercommand() {        ### create command to run docker
  local Line= Memory Tini=
  
  Dockercommand="$Containerbackendbin run"
  #[ "$Preservecachefiles" = "no" ] && Dockercommand="$Dockercommand --rm"
  case $Interactive in
    yes) 
      Dockercommand="$Dockercommand --interactive --tty" 
    ;;
    no)  
      Dockercommand="$Dockercommand --detach" 
      case "$Containerbackend" in
        nerdctl) ;;
        *) Dockercommand="$Dockercommand --tty" ;;
      esac
    ;;
  esac

  [ -z "$Containername" ] && Containername="x11docker_X${Newdisplaynumber}_${Codename}_${Cachenumber}"
  Dockercommand="$Dockercommand \\
  --name $Containername"
  storeinfo "containername=$Containername"
  
  [ "$Limitresources" ] && {
    Memory="$(awk "BEGIN {print int($(LC_ALL=C free -b | grep "Mem:" | awk ' {print $4 + $6}') * $Limitresources)}")"
    Dockercommand="$Dockercommand \\
  --cpus=$(awk "BEGIN {print $(nproc) * $Limitresources}") \\
  --memory=$Memory \\
  --kernel-memory=$Memory"
  }

  # container user. init systems switch later.
  case $Initsystem in
    none|tini|dockerinit)
      case $Switchcontaineruser in
        no) 
          [ "$Createcontaineruser" = "yes" ] && Dockercommand="$Dockercommand \\
  --user $Containeruseruid:$Containerusergid" ;;
        yes) 
          Dockercommand="$Dockercommand \\
  --user root" ;;
      esac
    ;;
    systemd|runit|openrc|sysvinit|s6-overlay)
      Dockercommand="$Dockercommand \\
  --user root" ;;
  esac
  
  [ "$Createcontaineruser" = "yes" ] && {
    # Disable user namespacing to avoid file permission issues with --home or --share. Files need same UID/GID.
    case $Containerbackend in
      podman) Dockercommand="$Dockercommand \\
  --userns=keep-id" ;;
      docker)
        [ "$Rootlessbackend" ] || {
          $Containerbackendbin run --help | grep -q -- '--userns' && Dockercommand="$Dockercommand \\
  --userns=host"
        }
      ;;
      *) $Containerbackendbin run --help | grep -q -- '--userns' && Dockercommand="$Dockercommand \\
  --userns=host" ;;
    esac
  }
  
  # add container user groups, mainly video and audio and --group-add
  [ "$Switchcontaineruser" = "no" ] && {
    $Containerbackendbin run --help | grep -q -- '--group-add' && {
      for Line in $Containerusergroups; do          ### FIXME: should compare GIDs from host and container
        getent group ${Line:-nonsense} >/dev/null && Dockercommand="$Dockercommand \\
  --group-add $(getent group $Line | cut -d: -f3)"
      done
      :
    } || {
      [ "$Containerusergroups" ] && note "Your backend $Containerbackend does not support option --group-add.
  Could not add container user to groups: $Containerusergroups
  Possible sound or GPU setup may fail."
    }
  }
  
  # Runtime runc|nvidia|kata
  [ "$Runtime" ] && {
    Dockercommand="$Dockercommand \\
  --runtime='$Runtime'"
  }

  # option --hostipc
  [ "$Sharehostipc" = "yes" ]      && Dockercommand="$Dockercommand \\
  --ipc host"
  
  # option --network
  [ "$Network" ] && Dockercommand="$Dockercommand \\
  --network $Network"
      
  # capabilities
  [ "$Capdropall" = "yes" ] && Dockercommand="$Dockercommand \\
  --cap-drop ALL"
  while read Line ; do
     Dockercommand="$Dockercommand \\
  --cap-add $Line"
  done < <(store_runoption dump cap)
  
  # default no, do not gain privileges
  [ "$Allownewprivileges" = "no" ] && Dockercommand="$Dockercommand \\
  --security-opt no-new-privileges"

  # SELinux restrictions for containers must be disabled to allow access to X socket. Flags z or Z do not help.
  Dockercommand="$Dockercommand \\
  --security-opt label=type:container_runtime_t"

  # stop signal for some init systems
  [ "$Stopsignal" ] &&  Dockercommand="$Dockercommand \\
  --stop-signal $Stopsignal"
  
  # setup and shared files for some init systems
  case $Initsystem in
    dockerinit)
      Dockercommand="$Dockercommand \\
  --init"
    ;;
    tini) 
      Tini="$Tinicontainerpath --"
      Dockercommand="$Dockercommand \\
  --volume $(convertpath volume "$Tinibinaryfile:ro" "$Tinicontainerpath")" 
    ;;
    systemd)
      Dockercommand="$Dockercommand \\
  -v $Systemdtarget:/etc/systemd/system/x11docker.target:ro \\
  -v $Systemdconsoleservice:/lib/systemd/system/console-getty.service:ro \\
  -v $Systemdwatchservice:/etc/systemd/system/x11docker-watch.service:ro \\
  -v $Systemdjournalservice:/etc/systemd/system/x11docker-journal.service \\
  -v $Systemdenvironment:/etc/systemd/system.conf.d/x11docker.environment.conf"
    ;;
  esac

  # option --sharecgroup
  [ "$Sharecgroup" = "yes" ] && Dockercommand="$Dockercommand \\
  --volume /sys/fs/cgroup:/sys/fs/cgroup:ro"

  # Needed especially for --init=systemd and --dbus-daemon
  case $Containerbackend in
    nerdctl) ;;
    *) Dockercommand="$Dockercommand \\
  --tmpfs /run:exec --tmpfs /run/lock" ;;
  esac

  # shared cache folder
  Dockercommand="$Dockercommand \\
  --volume $(convertpath volume "$Sharefolder:rw" $Sharefoldercontainer)"
  
  # --home
  case $Sharehome in
    host)
      Dockercommand="$Dockercommand \\
  --volume $(convertpath volume "$Persistanthomevolume:rw" "$Containeruserhome")"
    ;;
    volume)
      Dockercommand="$Dockercommand \\
  --volume '$Persistanthomevolume':'$Containeruserhomebasefolder':rw"
    ;;
  esac
  
  # --share
  while read -r Line; do
    case "$(cut -c1-5 <<< "$Line")" in
      "/dev/")
         Dockercommand="$Dockercommand \\
  --device $(convertpath volume "$Line")"
        warning "Sharing device file: $Line"
      ;;
      *)
        Dockercommand="$Dockercommand \\
  --volume $(convertpath volume "$Line")" 
      ;;
    esac
  done < <(store_runoption dump volume)
  
  # --gpu: share NVIDIA driver installer
  [ -e "$Nvidiainstallerfile" ] && Dockercommand="$Dockercommand \\
  --volume $(convertpath volume "$Nvidiainstallerfile:ro" "$Nvidiacontainerfile")"
  
  # X socket will be softlinked to /tmp/.X11-unix in containerrc
  [ "$Newxsocket" ] && {
    case $Containersetup in
      yes)
        Dockercommand="$Dockercommand \\
  --volume $(convertpath volume "$Newxsocket" "/X$Newdisplaynumber")"
      ;;
      no)
        Dockercommand="$Dockercommand \\
  --volume $(convertpath volume "$Newxsocket")"
      ;;
    esac
  }
  
  # Wayland socket will be softlinked to XDG_RUNTIME_DIR in containerrc
  [ "$Setupwayland" = "yes" ] && {
    case $Containersetup in
      yes)
        Dockercommand="$Dockercommand \\
  --volume $(convertpath volume "$XDG_RUNTIME_DIR/$Newwaylandsocket" "/$Newwaylandsocket")"
      ;;
      no)
        Dockercommand="$Dockercommand \\
  --volume $(convertpath volume "$XDG_RUNTIME_DIR/$Newwaylandsocket")"
      ;;
    esac
  }

  ## options --pulseaudio, --alsa
  { [ "$Pulseaudiomode" = "socket" ] || [ "$Sharealsa" = "yes" ] ; } && Dockercommand="$Dockercommand \\
  --volume $Pulseaudioconf:/etc/pulse/client.conf:ro"
  
  ## option --workdir or /tmp
  case $Containersetup in
    yes)
      Dockercommand="$Dockercommand \\
  --workdir '${Workdir:-/tmp}'"
    ;;
    no)
      [ "$Workdir" ] && Dockercommand="$Dockercommand \\
  --workdir '$Workdir'"
    ;;
  esac
  
  case $Containersetup in
    yes)
      # real entrypoint is checked in dockerrc
      Dockercommand="$Dockercommand \\
  --entrypoint env"
    ;;
  esac
  
  # add environment variables. Only needed here for possible 'docker exec'. Otherwise set in containerrc
  while read Line; do
    Dockercommand="$Dockercommand \\
  --env '$Line'"
  done < <(store_runoption dump env)
      
  # add custom docker arguments, imagename and imagecommand
  [ "$Customdockeroptions" ] && Dockercommand="$Dockercommand \\
  $Customdockeroptions"
  Dockercommand="$Dockercommand \\
  --"
  
  case $Containersetup in
    yes)
      case $Switchcontaineruser in
        no)  Dockercommand="$Dockercommand $Imagename $Tini /bin/sh - $(convertpath share $Containerrc)" ;;  # dockerrc runs containerrootrc with 'docker exec'
        yes) Dockercommand="$Dockercommand $Imagename $Tini /bin/sh - $(convertpath share $Containerrootrc)"  ;;    # containerrootrc runs containerrc
      esac
    ;;
    no)
      Dockercommand="$Dockercommand $Imagename $Containercommand"
    ;;
  esac

  return 0
}