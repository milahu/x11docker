setup_initsystem() {            # option init: set up capabilities, check or create files
  # some init system setup also in containerrootrc
  local Message=

  case $Initsystem in
    tini|systemd|sysvinit|openrc|runit|dockerinit|s6-overlay|none) ;;
    *) 
      note "Option --init: Unknown init system $Initsystem
  Possible: tini systemd sysvinit openrc runit s6-overlay none
  Fallback: Using --init=tini instead."
      check_fallback
      Initsystem="tini" 
    ;;
  esac
  
  # --init in Mobyvm. /usr/bin/docker-init is not available in MSYS2/Cygwin/WSL1
  case $Mobyvm in
    yes) [ "$Initsystem" = "tini" ] && Initsystem="dockerinit" ;;
  esac
  
  case "$X11dockermode" in
    exe) 
      case $Initsystem in
        tini|none) ;;
        dockerinit) Initsystem="none" ;;
        *) 
          note "Option --init: Only --init[=tini] or --init=none are 
  supported with option --exe. Fallback: Setting option --init=tini"
          check_fallback
          Initsystem="tini"
        ;;
      esac
    ;;
    run)
      store_runoption env "container=docker"   # At least OpenRC and systemd regard this hint
    ;;
  esac
  
  case $Initsystem in
    none|dockerinit) ;;
    tini)
      Tinibinaryfile="$(command -v docker-init ||:)"
      [ -z "$Tinibinaryfile" ]                                      && Tinibinaryfile="/snap/docker/current/bin/docker-init"
      [ -e "$Tinibinaryfile" ]                                      || Tinibinaryfile="/snap/docker/current/usr/bin/docker-init"
      [ -e "/usr/bin/tini-static" ]                                 && Tinibinaryfile="/usr/bin/tini-static"
      [ -e "/usr/local/share/x11docker/tini-static" ]               && Tinibinaryfile="/usr/local/share/x11docker/tini-static"
      [ -e "$Hostuserhome/.local/share/x11docker/tini-static" ]     && Tinibinaryfile="$Hostuserhome/.local/share/x11docker/tini-static"
      Tinibinaryfile="$(myrealpath "$Tinibinaryfile" 2>/dev/null ||:)"
      [ -e "$Tinibinaryfile" ]                                      || Tinibinaryfile=""
      [ "$Tinibinaryfile" ] && {
        case "$Runtime" in
          kata-runtime)
            # avoid sharing same file that might be shared with runc already.
            mkdir -p "$Hostuserhome/.local/share/x11docker"
            cp -u "$Tinibinaryfile"  "$Hostuserhome/.local/share/x11docker/tini-static-kata"
            Tinibinaryfile="$Hostuserhome/.local/share/x11docker/tini-static-kata"
          ;;
        esac
        [ -x "$Tinibinaryfile" ] || {
          chmod +x "$Tinibinaryfile" || {
            warning "Your tini binary is not executable. Please run
    chmod +x $Tinibinaryfile"
            Initsystem="none"
          }
        }
      } || Initsystem="none"
      [ "$Initsystem" = "none" ] && [ "$X11dockermode" = "run" ] && {
        note "Did not find container init system 'tini'.
  This is a bug in your distributions docker package.
  Normally, docker provides init system tini as '/usr/bin/docker-init'.

  x11docker uses tini for clean process handling and fast container shutdown.
  To provide tini yourself, please download tini-static:
    https://github.com/krallin/tini/releases/download/v0.18.0/tini-static
  Store it in one of:
    $Hostuserhome/.local/share/x11docker/
    /usr/local/share/x11docker/"
      }
      verbose "--init: Found tini binary: ${Tinibinaryfile:-(none)}"
      [ "$Tinibinaryfile" ] && storeinfo "tini=$Tinibinaryfile"
    ;;

    systemd)
      Stopsignal="SIGRTMIN+3"
      Containerusergroups="$Containerusergroups systemd-journal"

      echo "[Unit]
Description=x11docker target
Wants=multi-user.target
After=multi-user.target
[Install]
Also=console-getty.service
Also=x11docker-watch.service
Also=x11docker-journal.service
" >> $Systemdtarget

      echo "[Unit]
Description=x11docker start service 
# start on console to support --interactive
# runs x11docker-agetty->x11docker-login->containerrc
Wants=multi-user.target
Wants=x11docker-watch.service
Wants=x11docker-journal.service
Wants=dbus.service
After=systemd-user-sessions.service
After=rc-local.service getty-pre.target
Before=getty.target
[Service]
ExecStart=/usr/local/bin/x11docker-agetty
StandardInput=tty
StandardOutput=tty
Type=idle
UtmpIdentifier=cons
TTYPath=/dev/console
TTYReset=yes
TTYVHangup=yes
KillMode=process
IgnoreSIGPIPE=no
SendSIGHUP=yes

[Install]
WantedBy=x11docker.target
WantedBy=getty.target
WantedBy=multi-user.target
" >> $Systemdconsoleservice

      echo "[Unit]
Description=x11docker watch service
# Watches for end of containerrc and initiates shutdown
[Service]
Type=simple
ExecStart=/bin/sh -c 'while sleep 1; do systemctl is-active console-getty >/dev/null || { echo timetosaygoodbye >>$(convertpath share $Timetosaygoodbyefile) ; systemctl halt ; } ; [ -s $(convertpath share $Timetosaygoodbyefile) ] && systemctl halt ; done'
[Install]
WantedBy=x11docker.target
" >> $Systemdwatchservice

      echo "[Unit]
Description=x11docker journal log service
# get systemd log to transfer it into x11docker.log 
[Service]
Type=simple
ExecStart=/bin/sh -c '/bin/journalctl --follow --no-tail --merge >> $(convertpath share $Systemdjournallogfile) 2>&1'
[Install]
WantedBy=x11docker.target
" >> $Systemdjournalservice

      echo "[Manager]
DefaultEnvironment=$(while read -r Line; do echo -n "$Line " ; done < <(store_runoption dump env))
" >> $Systemdenvironment
    ;;

    runit)
      Stopsignal="HUP"
      store_runoption env "VIRTUALIZATION=docker"
    ;;
    openrc) 
    ;;
    sysvinit)
      Stopsignal="INT"
    ;;
    s6-overlay)
    ;;
  esac
  
  case $Initsystem in
    systemd)
      warning "Option --init=systemd slightly degrades container isolation.
  It adds some user switching capabilities x11docker would drop otherwise.
  However, they are still within default docker capabilities.
  Not within default docker capabilities it adds capability SYS_BOOT.  
  It shares access to host cgroups in /sys/fs/cgroup.
  Some processes in container will run as root."
    ;;
    runit|openrc|sysvinit) 
      warning "Option --init=$Initsystem slightly degrades container isolation.
  It adds some user switching capabilities x11docker would drop otherwise.
  However, they are still within default docker capabilities.
  Not within default docker capabilities it adds capability SYS_BOOT.
  Some processes in container will run as root."
    ;;
    s6-overlay) 
      warning "Option --init=$Initsystem slightly degrades container isolation.
  It adds some user switching capabilities x11docker would drop otherwise.
  However, they are still within default docker capabilities.
  Some processes in container will run as root."
    ;;
    tini|none|dockerinit) 
      [ "$Dbussystem" = "yes" ] && {
        [ "$Capdropall" = "yes" ] && warning "Option --dbus=system slightly degrades container isolation.
  It adds some user switching capabilities x11docker would drop otherwise.
  However, they are still within default docker capabilities.
  Some processes in container will run as root.
  --dbus=system might need further capabilities or --cap-default to work
  as expected. If in doubt, one of --init=systemd|openrc|runit|sysvinit 
  might be a better choice."
        note "Option --dbus=system with init system '$Initsystem'
  can have a quite long timeout delay until startup.
  Use one of --init=systemd|openrc|runit|sysvinit in that case."
      }
    ;;
  esac
  
  return 0
}