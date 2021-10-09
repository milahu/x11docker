main() {
  trap finish EXIT
  trap finish_sigint SIGINT
  
  exec {FDstderr}>&2            # stderr channel for warning(), error(), note(), debugnote() and --verbose
  
  declare_variables
  parse_options "$@"
  
  [ -n "$Containeruserpassword" ] && {                                            # --password
    command -v perl >/dev/null || error "Option --password: command 'perl' not found.
  perl is needed to generate an encrypted password."
    [ "$Containeruserpassword" = "INTERACTIVE" ] && {
      read -rs -p "Please type in a new container user password (chars are invisible): " Containeruserpassword
      echo ""
      [ -z "$Containeruserpassword" ] && error "Empty input, password not changed."
    }
    Containeruserpassword="$(perl -e "print crypt(\"$Containeruserpassword\", \"salt\")")"
    mkdir -p "$(dirname "$Passwordfile")"
    echo "$Containeruserpassword" > "$Passwordfile"
    chmod 600                       "$Passwordfile"
    note "Option --password: Password changed, exiting."
    finish
  }

  [ "$Silent" = "yes" ]    && exec {FDstderr}>/dev/null                           # --quiet
  [ "$Debugmode" = "yes" ] && {                                                   # --debug
    set -Eu
    trap 'traperror $? $LINENO $BASH_LINENO "$BASH_COMMAND" $(printf "::%s" ${FUNCNAME[@]})'  ERR
  }
  
  # check host, create cache
  check_host                    # get some infos about host system #time0,234
  check_runmode                 # modes: run image, or host command, or X only    # --exe, --xonly
  check_hostuser                # find unprivileged host user                     # --hostuser
  create_cachefiles             # create cache files owned by unprivileged user   # --cachebasedir
  check_hostxenv                # check X environment from host
  storeinfo "x11dockerpid=$$"   # store pid of x11docker

  debugnote "
x11docker version: $Version
Backend version:   $($Containerbackendbin --version 2>&1)
Host system:       $(grep '^PRETTY_NAME' /etc/os-release 2>/dev/null | cut -d= -f2 || echo "$Hostsystem")
Host architecture: $Hostarchitecture
Command:           '$0' $(for Line in "$@"; do echo -n "'$Line' " ; done)
Parsed options:    $Parsedoptions_global"

  # Special x11docker jobs
  [ "$Createlauncher" = "yes" ] && { create_launcher ; exit ; }                   # --launcher: Create application launcher icon on desktop
  [ "$Cleanup" = "yes" ]        && { cleanup ;         exit ; }                   # --cleanup: Clean up cache and orphaned x11docker containers
  [ "$Installermode" ]          && { installer "$Installermode" ; exit ; }        # --install, --update, --update-master, --remove
  [ "$Buildimage" ]             && { buildimage "$Imagename" ; exit ; }           # --build: Build image from x11docker repository

  # check options
  case "$Fallback" in
    yes|no) ;;
    *) error "Option --fallback: Unknown argument '$Fallback'" ;;
  esac
  
  # Docker installed in snap (noteable Ubuntu Server)
  [ "$Runsinsnap" = "yes" ] && [ -z "$Snapsupport" ] && {
    note "It seems docker runs in snap.
  This limits possibilities to use docker and x11docker.
  Fallback: Enabling option --snap"
    Snapsupport="yes"
    check_fallback
  }
  [ -d "/snap/docker" ] && [ "$Snapsupport" = "no" ] && note "Detected /snap/docker.
  If you run Docker in snap, you might need option --snap to support this setup."
  [ "$Snapsupport" = "yes" ] && {
    note "Option --snap causes some restrictions.
  Option --newprivileges=yes is enabled.
  Option --hostdisplay is not available because X must be accessed over TCP. 
  Option --gpu only works with --xorg and --network=host.
  It is recommended to purge the Docker snap installation and to install Docker natively."
    [ "$Allownewprivileges" = "auto" ] && Allownewprivileges="yes"
    Xoverip="yes"
  }
  
  check_xserver                  # check chosen X server or auto-choose one
  check_option_interferences     # check options, change settings if needed
  option_messages                # some messages depending on options, but not changing anything
  
  # container user
  check_containeruser            # unprivileged user in container                 # --user
  check_containerhome            # create persistent container home               # --home, --homebasedir
  
  # some checks and setup
  drop_cachefiles                # remove cachefiles not needed for current setup
  setup_verbosity                # create [and show] summary logfile              # --verbose
  setup_fifo                     # open message channels for container, dockerrc, xinitrc and watchpidlist()
  check_screensize               # size of host X and of new X server             # --size #time0,213
  [ "$Windowmanagermode" ]       && check_windowmanager                           # --wm  
  [ "$Sharegpu" = "yes" ]        && setup_gpu ||:                                 # --gpu
  [ "$Sharewebcam" = "yes" ]     && setup_webcam                                  # --webcam
  [ "$Sharecupsmode" ]           && setup_printer                                 # --printer
  [ "$Pulseaudiomode" ]          && setup_sound_pulseaudio                        # --pulseaudio
  [ "$Sharealsa" = "yes" ]       && setup_sound_alsa                              # --alsa
  [ "$Cleanxhost" = "yes" ]      && clean_xhost                                   # --clean-xhost
  
  #### Create command to run X server [and/or Wayland compositor]
  [ "$Xserver" != "--xorg" ]     && [ -n "$Newxvt" ]              && note "Option --vt only takes effect with option --xorg."
  [ "$Xserver" = "--xorg" ]      && [ -z "$Newxvt" ]              && check_vt     # --vt: find free tty/virtual terminal for Xorg
  { [ "$Xserver" = "--xdummy" ]  || [ "$Xpravfb" = "Xdummy" ] ; } && create_xdummyxorgconf > $Xdummyconf && create_xdummywrapper > $Xorgwrapper
  check_newxenv                  # find free display, create $Newxenv
  create_xcommand                # set up start command for X server              # all X server and Wayland options
  [ "$Xcommand" ]                && debugnote "X server command:
  $Xcommand"
  [ "$Compositorcommand" ]       && debugnote "Compositor command:
  $Compositorcommand"
  [ "$Shareclipboard" = "yes" ]  && setup_clipboard ||:                           # --clipboard
    
  check_terminalemulator         # find terminal emulator like xterm for error messages and 'docker pull'
  check_passwordfrontend         # check for su/sudo/gksu/pkexec etc.             # --pw #time0,230
  setup_initsystem               # init in container. Default: tini               # --init
  [ "$Runsinterminal" = "no" ]   && [ "$Passwordneeded" = "yes" ] && warning "You might need to run x11docker in terminal
  for password prompt if prompting for password with a GUI fails."
  
  debugnote "Users and terminal:
  x11docker was started by:                       $Startuser
  As host user serves (running X, storing cache): $Hostuser
  Container user will be:                         $( [ "$Createcontaineruser" = "yes" ] && echo $Containeruser || echo "(retaining USER of image)")
  Container user password:                        $( [ "$Createcontaineruser" = "yes" ] && echo x11docker      || echo "(unknown)")
  Getting permission to run backend with:         $Passwordcommand $Sudo
  Terminal for password frontend:                 $Passwordterminal
  Running in a terminal:                          $Runsinterminal
  Running on console:                             $Runsonconsole
  Running over SSH:                               $Runsoverssh
  Running sourced:                                $Runssourced
  bash \$-:                                        $-"
  [ "$Winsubsystem" ] && debugnote "
  Running on Windows subsystem:                   $Winsubsystem
  Path to subsystem:                              $(convertpath windows $Winsubpath)/
  Mount path in subsystem:                        $Winsubmount/
  Using MobyVM:                                   $Mobyvm"

  #### Create docker command
  [ "$X11dockermode" = "run" ] && {
    # core setup of docker command
    setup_capabilities          # add linux capabilities if needed for some options. Default: --cap-drop=ALL
    [ "$Sharehostdbus" = "yes" ] && setup_hostdbus                                # --hostdbus
    create_dockercommand        # create 'docker run' command #time0,631
    echo "$Dockercommand" >> $Dockercommandfile
    
    debugnote "$Containerbackend command:
  $Dockercommand"
    
    #### Create helper scripts to set up container
    ## dockerrc runs as root (or member of group docker) on host.d
    # Main jobs: check image, pull image if needed, create script containerrc to run container command
    create_dockerrc > $Dockerrc
    verbose "Generated dockerrc:
$(nl -ba <$Dockerrc)"
    ## containerrootrc runs as root in container.
    # Main jobs: create unprivileged container user, disable possible privilege leaks, set local time.
    # Optional jobs: run init system, run DBus daemon, install nvidia driver, create language locale.
    [ "$Containersetup" = "yes" ] && {
      create_containerrootrc  > $Containerrootrc
      verbose "Generated containerrootrc:
$(nl -ba <$Containerrootrc)"
    }
    create_xtermrc > $Xtermrc              # xtermrc to prompt for password if needed.
  }
  
  #### Create helper script xinitrc to set up X
  ## xinitrc is started by xinit and does some setup within new X server.
  # Main job: create cookie, check xhost, set keyboard layout.
  # Optional jobs: run window manager, run xfishtank, run host command, share clipboard, scale/rotate --xorg, create set of screen resolutions.
  create_xinitrc > $Xinitrc
  verbose "Generated xinitrc:
$(nl -ba <$Xinitrc)"
  [ -s "$Westonini" ] && verbose "Generated weston.ini:
$(nl -ba <$Westonini)"

  { #### Run docker image
    # For code flow logic, start_xserver() should run here first and be moved to background.
    # For technical reasons, xinit must not run in a subshell:
    #   --xorg on tty only works if xinit runs in foreground to grab the tty.
    #   Otherwise, Xwrapper.config must be edited to 'allowed_users=anybody' even on console.
    # Thus docker runs in this subshell after X server is ready to accept connections.
    # Waiting for X is done in dockerrc.
    
    trap '' SIGINT
    
    # start container
    case $X11dockermode in
      run) start_docker ;;                                                        # (default)
      exe) start_hostexe ;;                                                       # --exe, --xonly
    esac
    Pid1pid="$(storeinfo dump pid1pid)"
    
    # watch container
    case $X11dockermode in
      run)  
        case "$Winsubsystem" in
          "") setonwatchpidlist "${Pid1pid:-NOPID}" pid1pid ;;
          *)  setonwatchpidlist "CONTAINER$Containername" ;;
        esac
      ;;
      exe)     setonwatchpidlist "${Pid1pid:-NOPID}" pid1pid ;;
    esac
        
    # watch xinit and X server
    case $Xserver in
      --tty|--hostdisplay|--hostwayland|--weston|--kwin) ;;
      *)
        Xinitpid="$(pgrep -a xinit 2>/dev/null | grep "xinit $Xinitrc" | awk '{print $1}')"
        checkpid "$Xinitpid"   && setonwatchpidlist $Xinitpid xinit
        echo $Xcommand | grep -q Xorgwrapper && Line="Xorg $Newdisplay" || Line="$(head -n1 <<< "$Xcommand" | tr -d '\\')"
        Xserverpid=$(ps aux | rmcr | grep "$(echo "${Line:-nothingtolookfor}" | cut -d' ' -f1-2)" | grep -v grep | grep -v xinit | awk '{print $2}')
        checkpid "$Xserverpid" && setonwatchpidlist "$Xserverpid" Xserver
      ;;
    esac

    [ "$Pulseaudiomode" = "tcp" ] && start_pulseaudiotcp                          # --pulseaudio=tcp

    # some debug output
    checkpid "$Pid1pid" && debugnote "Process tree of ${Hostexe:-container}: (maybe not complete yet)
$(pstree -cp $Pid1pid 2>&1 ||:)"
    debugnote "Process tree of x11docker:
$(pstree -p $$ 2>&1 ||:)
  $(storepid test dockerstopshell && echo "Lost child of dockerrc (dockerstopshell):
    $(pstree -p $(storepid dump dockerstopshell) 2>&1 ||:)")"
    debugnote "storeinfo(): Stored info:
$(cat $Storeinfofile)"
    debugnote "storepid(): Stored pids:
$(cat $Storepidfile)"
    
    # optional info on stdout
    [ "$Showinfofile" = "yes" ]           && echo "$Storeinfofile"                # --showinfofile
    [ "$Showcache" = "yes" ]              && echo "$Cachefolder"                  # --showcache (x11docker-gui only)
    [ "$Showdisplayenvironment" = "yes" ] && echo "$(storeinfo dump Xenv)"        # --showenv
    [ "$Showcontainerid" = "yes" ]        && echo "$(storeinfo dump containerid)" # --showid
    [ "$Showcontainerpid1pid" = "yes" ]   && echo "$Pid1pid"                      # --showpid1
    
    storeinfo "x11docker=ready"
  } <&0 & storepid $! containershell
  
  #### Start X server [and/or Wayland compositor] [and xpra]
  waitforlogentry "start_xserver()" $Storeinfofile "readyforX=ready" "" infinity
  [ "$Xpraservercommand" ] && {
    {
      waitforlogentry xpra $Storeinfofile "xinitrc=ready" infinity
      rocknroll || exit 0
      start_xpra                                                                    # --xpra, --xpra-xwayland
    } & storepid $! xpraloop
  }
  rocknroll && [ "$Compositorcommand" ] && start_compositor
  rocknroll && start_xserver

  saygoodbye main
}