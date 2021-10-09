parse_options() {               # parse cli options
  local Shortoptions Longoptions Parsedoptions Presetoptions Presetfile
  Shortoptions="aAcdDefFghHiIKlmnpPqtTvVwWxXyY"
  Longoptions="exe,xonly"                                                                                                  # Alternate setups of x11docker
  Longoptions="$Longoptions,auto,desktop,tty,wayland,wm::"                                                                 # Influencing auto-setup of X/Wayland/x11docker
  Longoptions="$Longoptions,hostdisplay,nxagent,runx,xdummy,xephyr,xpra,xorg,xvfb,xwin"                                    # X servers
  Longoptions="$Longoptions,kwin-xwayland,weston-xwayland,xpra-xwayland,xwayland"                                          # X servers depending on a Wayland compositor
  Longoptions="$Longoptions,hostwayland,kwin,weston"                                                                       # Wayland compositors without X
  Longoptions="$Longoptions,border::,dpi:,fullscreen,output-count:,rotate:,scale:,size:,xfishtank"                         # X/Wayland appearance options
  Longoptions="$Longoptions,clean-xhost,composite::,display:,iglx,keymap:,no-auth,vt:,westonini:,xhost::,xoverip,xtest::"  # X/Wayland config
  Longoptions="$Longoptions,enforce-i,fallback::,preset:,pull::,pw::"                                                      # x11docker config
  Longoptions="$Longoptions,cachebasedir:,home::,homebasedir:,share:"                                                      # Host folders
  Longoptions="$Longoptions,alsa::,clipboard,gpu,lang::,printer::,pulseaudio::,webcam"                                     # Host integration features
  Longoptions="$Longoptions,env:,mobyvm,name:,no-entrypoint,runtime:,snap,workdir:"                                        # Container config
  Longoptions="$Longoptions,cap-default,hostipc,limit::,newprivileges::,network::"                                         # Container capabilities
  Longoptions="$Longoptions,group-add:,hostuser:,password::,sudouser::,user:,shell:"                                       # Container user
  Longoptions="$Longoptions,dbus::,init::,hostdbus,sharecgroup"                                                            # Container init and DBus
  Longoptions="$Longoptions,stdin,interactive"                                                                             # Container interaction
  Longoptions="$Longoptions,runasuser:,runfromhost:,runasroot:"                                                            # Additional commands to execute
  Longoptions="$Longoptions,showenv,showid,showinfofile,showpid1,showcache"                                                # Output of vars on stdout
  Longoptions="$Longoptions,debug,quiet,verbose"                                                                           # Verbose options
  Longoptions="$Longoptions,build,cleanup,help,launcher,licence,license,version,wmlist"                                    # Special options without starting X or container
  Longoptions="$Longoptions,install,remove,update,update-master"                                                           # Installation
  #
  Longoptions="$Longoptions,backend:,keepcache,no-setup,podman,xopt:,xorgconf:"                                            # Experimental
  Longoptions="$Longoptions,dbus-system,homedir:,hostnet,no-internet,no-xhost,sharedir:,sharessh,systemd"                  # Deprecated
  Longoptions="$Longoptions,cachedir:,no-init,nothing,no-xtest,openrc,ps,runit,silent,starter,stderr,stdout"               # Removed
  Longoptions="$Longoptions,sys-admin,sysvinit,tini,trusted,untrusted,vcxsrv"                                              # Removed

  Parsererrorfile="/tmp/x11docker.parserserror.$Cachenumber"
  Parsedoptions="$(getopt --options "$Shortoptions" --longoptions "$Longoptions" --name "$0" -- "$@" )" || error "Failed to parse options."
  eval set -- "$Parsedoptions"
  [ -z "$Parsedoptions_global" ] && Parsedoptions_global="$Parsedoptions"
  
  [ "$*" = "-h --" ] &&       usage &&        exit 0                 # Catch single -h for usage info, otherwise it means --hostdisplay
  [ "$*" = "--" ]    &&       usage &&        exit 0                 # x11docker without options
  [ "$*" = "-- --" ] &&       usage &&        exit 0                 # x11docker-gui without options
  
  while [ $# -gt 0 ]; do
    case "${1:-}" in
      --hostdisplay|--hostwayland|--kwin|--kwin-xwayland|--nxagent|--tty|--weston|--weston-xwayland|--xpra-xwayland|--xephyr|--xorg|--xwayland|--xwin|-h|-H|-K|-n|-t|-T|-Y|-y|-A|-x|-X)
        [ -n "$Xserver" ] && note "Please use only one X server or Wayland option at a time.
  You have set option '${1:-}' after option '$Xserver'.
  ${1:-} will take effect."
      ;;
      --xpra|--xvfb|--xdummy|-a)
        case $Xserver in
          "") ;;
          --xpra|-a) ;;
          --xvfb|--xdummy)
            [ "${1:-}" != "--xpra" ] && note "Please use only one X server or Wayland option at a time.
  You have set option '${1:-}' after option '$Xserver'.
  ${1:-} will take effect."
          ;;
          *)
            note "Please use only one X server or Wayland option at a time.
  You have set option '${1:-}' after option '$Xserver'.
  ${1:-} will take effect."
          ;;
        esac
      ;;
    esac
    case "${1:-}" in
         --help)              usage ;         exit 0 ;;              # Show help/usage and exit
         --license|--licence) license ;       exit 0 ;;              # Show MIT license and exit
         --version)           echo $Version ; exit 0 ;;              # Output version number and exit
         --wmlist)            echo $Wm_all ;  exit 0 ;;              # Special option for x11docker-gui to retrieve list of window managers

      -e|--exe)               X11dockermode="exe" ;;                 # Execute application from host instead of running docker image
         --xonly)             X11dockermode="xonly" ;;               # Only create X server
         
     #### Predefined option sets
         --preset)            Presetoptions=""
                              Presetfile=""
                              [ -f "$Presetdirsystem/${2:-}" ] && Presetfile="$Presetdirsystem/${2:-}"
                              [ -f "$Presetdirlocal/${2:-}" ]  && Presetfile="$Presetdirlocal/${2:-}"
                              [ -f "/${2:-}" ]                 && Presetfile="/${2:-}"
                              [ -f "$Presetfile" ]             || error "Option --preset: File not found: ${2:-}
  Searching as an absolute path and in:
  $Presetdirlocal
  $Presetdirsystem"
                              Presetoptions="$(sed '/^#/d' < "$Presetfile" | tr '\n' ' ')"
                              debugnote "--preset ${2:-}: 
  $Presetoptions"
                              [ "$Presetoptions" ] && eval parse_options $Presetoptions
                              shift ;; 

     #### Choice of X servers and Wayland compositors
         --auto)              Autochooseserver="yes" ;;              # Default: auto-choose X server or Wayland compositor
      -h|--hostdisplay)       Xserver="--hostdisplay" ;;             # Host display :0 with shared X socket
      -H|--hostwayland)       Xserver="--hostwayland" ;;             # Host wayland. Allows coexistence with option
      -K|--kwin)              Xserver="--kwin" ;;                    # KWin, Wayland only
         --kwin-xwayland)     Xserver="--kwin-xwayland" ;;           # KWin + Xwayland
      -n|--nxagent)           Xserver="--nxagent" ;;                 # nxagent
         --runx)              Xserver="--runx" ;;                    # MS Windows: Will be Xwin or VcXsrv
      -t|--tty)               Xserver="--tty"  ;;                    # Do not provide any X nor Wayland
      -T|--weston)            Xserver="--weston" ;;                  # Weston, Wayland only
      -Y|--weston-xwayland)   Xserver="--weston-xwayland" ;;         # Weston + Xwayland
         --xdummy)            [ "$Xserver" = "--xpra" ]   && Xpravfb="Xdummy" || Xserver="--xdummy" ;;  # Xdummy. Invisible on host.
      -y|--xephyr)            Xserver="--xephyr" ;;                  # Xephyr
      -a|--xpra)              [ "$Xserver" = "--xdummy" ] && Xpravfb="Xdummy"
                              [ "$Xserver" = "--xvfb" ]   && Xpravfb="Xvfb"
                              Xserver="--xpra" ;;                    # xpra
      -A|--xpra-xwayland)     Xserver="--xpra-xwayland" ;;           # Xpra with vfb Xwayland
      -x|--xorg)              Xserver="--xorg" ;;                    # Xorg
         --xvfb)              [ "$Xserver" = "--xpra" ]   && Xpravfb="Xvfb" || Xserver="--xvfb" ;;      # Xvfb. Invisible on host.
      -X|--xwayland)          Xserver="--xwayland" ;;                # Xwayland on already running Wayland
         --xwin)              Xserver="--xwin" ;;                    # XWin, MS Windows only

     #### Influencing automatic choice of X server or Wayland compositor
      -d|--desktop)           Desktopmode="yes" ;;                   # image contains a desktop environment.
      -g|--gpu)               Sharegpu="yes" ;;                      # share files in /dev/dri, allow GPU usage
      -W|--wayland)           Setupwayland="yes" ;;                  # set up wayland environment, regards --desktop
      -w)                                      Windowmanagermode="auto" ; Desktopmode="yes" ;;
         --wm)                case "${2:-}" in                       # choose window manager
                                "n"|"none")    Windowmanagermode="none" ;;
                                "host")        Windowmanagermode="host" ;;
                                ""|"auto"|"m") Windowmanagermode="auto" ;;
                                *)             Windowmanagermode="auto"; Windowmanagercommand="${2:-}" ;;
                              esac
                              shift ; Desktopmode="yes" ;;

     #### X and Wayland appearance
         --border)            Xpraborder="${2:-"blue,1"}"; shift ;;  # Colored border for xpra clients
         --dpi)               Dpi=${2:-} ; shift ;;                  # Dots per inch. Influences font size
      -f|--fullscreen)        Fullscreen="yes"  ;;                   # Fullscreen mode for Xephyr and Weston
         --output-count)      Outputcount="${2:-}" ; shift ;;        # Number of virtual outputs
         --rotate)            Rotation=${2:-} ; shift ;;             # Rotation and mirroring
         --scale)             Scaling=${2:-} ; shift ;;              # Zoom
         --size)              Screensize="${2:-}" ;  shift ;;        # Screen size
      -F|--xfishtank)         Xfishtank="yes" ;;                     # Run xfishtank on new X server

     #### X and Wayland configuration
         --composite)         Xcomposite="${2:-yes}" ; shift ;;      # Enable or disable X extension COMPOSITE
         --display)           Newdisplaynumber="${2:-}"              # Display number to use for new X server or Wayland compositor
                              [ "$(echo $Newdisplaynumber | cut -c1)" = ":" ] && Newdisplaynumber="$(echo $Newdisplaynumber | cut -c2-)"
                              shift ;;
         --iglx)              Iglx="yes" ;;                          # Indirect rendering; broken since Xorg ~18.2 except with closed NVIDIA. libgl needs a fix.
         --keymap)            Xkblayout="${2:-}" ; shift ;;          # Keymap layout for xkbcomp. Compare /usr/share/X11/xkb/symbols
         --vt)                Newxvt="${2:-}" ; shift ;;             # Virtual console to use for --xorg
         --xoverip)           Xoverip="yes" ;;                       # Use X over TCP/IP instead of sharing X socket
         --xtest)             case "${2:-}" in                       # X extension XTEST
                                yes|"") Xtest="yes" ;;
                                no)     Xtest="no" ;;
                                *) warning "Invalid argument for option --xtest [=yes|no]: ${2:-}" ;;
                              esac; shift ;;
         --westonini)         Customwestonini="${2:-}" ; shift ;;    # Custom weston.ini
         
     #### X Authentication
         --clean-xhost|--no-xhost) Cleanxhost="yes"                  # Disable xhost credentials on host X
                              [ "${1:-}" = "--no-xhost" ] && note "Option --no-xhost is deprecated.
  Please use --clean-xhost instead." ;;
         --no-auth)           Xauthentication="no" ;;                # Disable cookie authentication on new X, set xhost +. Use for debugging only
         --xhost)             Xhost="${2:-auto}" ; shift ;;          # Custom xhost setting on new X server
         
     #### Host integration options
         --alsa)              Sharealsa="yes"                        # ALSA sound (shares /dev/snd)
                              Alsacard="${2:-$Alsacard}" ; shift ;;
      -c|--clipboard)         Shareclipboard="yes"  ;;               # Clipboard sharing
      -l)                     Langwunsch="$Langwunsch
${LANG:-}"                                                           # Locale/language setting
                              Langwunsch="${Langwunsch:-$LC_ALL}"
                              [ "$Langwunsch" ] || note "Option --lang: Environment variable \$LANG is empty.
  Please specify desired language locale with e.g. --lang=en_US or --lang=zh_CN." ;;
         --lang)              Langwunsch="$Langwunsch
${2:-${LANG:-}}" ; shift                                             # Locale/language setting
                              Langwunsch="${Langwunsch:-$LC_ALL}"
                              [ "$Langwunsch" ] || note "Option --lang: Environment variable \$LANG is empty.
  Please specify desired language locale with e.g. --lang=en_US or --lang=zh_CN." ;;
      -P|--printer)           Sharecupsmode="${2:-auto}" ; shift ;;   # Printer sharing with CUPS
      -p)                     Pulseaudiomode="auto" ;;               # Pulseaudio sound
         --pulseaudio)        Pulseaudiomode="${2:-auto}"; shift ;;  # Pulseaudio sound
         --webcam)            Sharewebcam="yes" ;;                   # Webcam sharing

     #### Special options
         --enforce-i)         ;;                                     # Run in bash interactive mode. Parsed at begin of script, nothing to do here.
         --fallback)          Fallback="${2:-yes}" ; shift ;;        # Allow/deny fallbacks for impossible options
      -i|--interactive)       Interactive="yes" ;;                   # Interactive terminal
         --pull)              Pullimage="${2:-yes}" ; shift ;;       # Allow 'docker pull'
         --pw)                Passwordfrontend="${2:-auto}" ; shift ;;   # Password prompt frontend
         --runasroot)         Runasroot="$Runasroot
${2:-}"                       ; shift ;;                             # Add custom root command in container setup script
         --runasuser)         Runasuser="$Runasuser
${2:-}"                       
                              shift ;;                               # Add custom user command in cmdrc   
         --runfromhost)       Runfromhost="$Runfromhost
${2:-}"                       ; shift ;;                             # Add custom host command in xinitrc

     #### User settings
         --group-add)         Containerusergroups="$Containerusergroups ${2:-}" ; shift ;; # Additional groups for container user
         --hostuser)          Hostuser="${2:-}" ; shift ;;           # Set host user different from logged in user
         --password)          Containeruserpassword="${2:-INTERACTIVE}" ; shift ;; # Change encrypted password in ~/.config/x11docker/passwd
         --shell)             Containerusershell="${2:-}" ; shift ;; # Set preferred user shell
         --sudouser)          Sudouser="${2:-yes}" ; shift ;;        # su and sudo for container user with password x11docker
         --user)              Containeruser="${2:-}"  ; shift        # Set container user other than host user
                              [ "$Containeruser" = "RETAIN" ] && Createcontaineruser="no" ;;
               
     #### Init system and DBus
         --dbus)              Dbusrunsession="${2:-yes}" ; shift ;;  # DBus in container, Default: user session, =system: with system daemon
         --hostdbus)          Sharehostdbus="yes" ;;                 # Connect to host DBus
         --init)              Initsystem="${2:-tini}" ; shift ;;     # init in container
         --sharecgroup)       Sharecgroup="yes" ;;                   # Share /sys/fs/cgroup. Default for --init=systemd, possible use with --init=openrc or elogind.
         --systemd)           Initsystem="systemd" ; note "Option --systemd is deprecated. Please use: --init=systemd" ;;

     #### Container configuration
         --backend)           Containerbackend="${2:-}" ; shift ;;   # container backend to use: docker, podman, nerdctl, others            
         --cap-default)       Capdropall="no" ;;                     # Don't use --cap-drop=ALL --security-opt=no-new-privileges
         --env)               store_runoption env "${2:-}"           # Set container environment variables
                              shift ;;
         --hostipc)           Sharehostipc="yes" ;;                  # docker run option --ipc=host
         --limit)             Limitresources="${2:-0.5}" ; shift ;;  # Limited CPU and RAM access
         --mobyvm)            Mobyvm="yes" ;;                        # Use MobyVM in WSL2
         --name)              Containername="${2:-}" ; shift ;;      # Set container name
      -I)                     Network="" ;;
         --network)           Network="${2:-}" ; shift ;;
         --newprivileges)     Allownewprivileges="${2:-yes}" ; shift ;; # [Don't] set --security-opt=no-new-privileges
         --no-entrypoint)     Noentrypoint="yes" ;;                  # Disable ENTRYPOINT of image
         --no-setup)          Containersetup="no" ;;                 # No setup of x11docker inside of container (noteable disables containerrootrc() )            
         --runtime)           Runtime="${2:-}" ; shift               # Runtime=runc|nvidia|kata-runtime|crun
                              [ "$Runtime" = "kata" ] && Runtime="kata-runtime" ;;
         --snap)              Snapsupport="yes" ;;                   # snap fallback mode
         --stdin)             Forwardstdin="yes" ;;                  # Forward stdin to container command
         --workdir)           Workdir="${2:-}" ; shift ;;            # Set working directory

     #### host folders and docker volumes
      -m)                     Sharehome="host" ;;
         --home|--homedir)    Sharehome="yes"                        # Share host folder as HOME in container, ~/x11docker/imagename or $2
                              [ "${1:-}" = "--homedir" ] && note "Option --homedir is deprecated.
  Please use --home=DIR instead."
                              Persistanthomevolume="${2:-}" ; shift ;;
         --share|--sharedir)  store_runoption volume "${2:-}"         # Share host file, device or directory
                              [ "${1:-}" = "--sharedir" ] && note "Option --sharedir is deprecated.
  Please use option --share=PATH instead."
                              shift ;;
         --homebasedir)       Hosthomebasefolder="${2:-}" ; shift ;; # Set base folder for --home instead of ~/.local/share/x11docker
         --cachebasedir)      Cachebasefolder="${2:-}" ; shift ;;    # Set base folder for cache  instead of ~/.cache/x11docker

     #### Verbosity options
      -D|--debug)             Debugmode="yes" ;;                     # Debugging mode
         --showinfofile)      Showinfofile="yes" ;;                  # Show path to $Storeinfofile
      -v|--verbose)           Verbose="yes" ;;                       # Be verbose  
      -V)                     Verbose="yes"; Verbosecolors="yes";;   # Be verbose with colored output
      -q|--quiet)             Silent="yes" ;;                        # Do not show warnings or errors
         --showcache)         Showcache="yes" ;;                     # Output of $Cachefolder. For x11docker-gui only
         --showenv)           Showdisplayenvironment="yes" ;;        # Output of display number and cookie file on stdout. Catch with: read xenv < <(x11docker --showenv)
         --showid)            Showcontainerid="yes" ;;               # Output of container id on stdout
         --showpid1)          Showcontainerpid1pid="yes" ;;          # Output of host PID of container PID 1

     #### Special options not starting X or docker
         --build)             Buildimage="yes" ;;                    # Build an image from x11docker repository
         --cleanup)           Cleanup="yes"  ;;                      # Remove orphaned containers and cache files
         --install|--update|--update-master|--remove) Installermode="${1:-}" ;;   # Installer
         --launcher)          Createlauncher="yes" ;;                # Create application launcher on desktop and exit
      
     #### Experimental options
         --keepcache)         Preservecachefiles="yes" ;          note "Option --keepcache: experimental option." ;;    
         --xopt)              Xserveroptions="${2:-}" ;   shift ; note "Option --xopt: experimental option." ;;      # Custom X server options
         --xorgconf)          Xorgconf="${2:-}" ;         shift ; note "Option --xorgconf: experimental option." ;;  # Custom xorg.conf
      
     #### Deprecated options
         --dbus-system)       note "Option --dbus-system is deprecated.
  Please use one of --init=systemd|openrc|runit|sysvinit instead.
  Fallback: Enabling options --dbus=system --cap-default"
                              check_fallback
                              Dbusrunsession="system"
                              Capdropall="no" ;;
         --hostnet)           Network="host" 
                              note "Option --hostnet is deprecated.
  Please use --network=host instead." ;;
         --no-internet)       Network="none"
                              note "Option --no-internet is deprecated.
  Please use --network=none instead." ;;
         --podman)            Containerbackend="podman" ;         note "Option --podman is deprecated. Use --backend=podman instead." ;;         
         --sharessh)          [ -e "${SSH_AUTH_SOCK:-}" ] && {       # SSH socket sharing
                                store_runoption volume "$(dirname $SSH_AUTH_SOCK)"
                                store_runoption env "SSH_AUTH_SOCK=$(escapestring "${SSH_AUTH_SOCK:-}")"
                              } || note "Option --sharessh: environment variable \$SSH_AUTH_SOCK not set:" ; 
                              note "Option --sharessh is deprecated.
  Please use (directly or with help of option --preset):
  --share \$(dirname \$SSH_AUTH_SOCK) --env SSH_AUTH_SOCK=\"\$SSH_AUTH_SOCK\"" ;;
                       
     #### Removed options
         --vcxsrv)            error "Option --vcxsrv is no longer supported.
  Please use either option --xwin in Cygwin/X
  or run x11docker with runx in WSL or MSYS2. 
  For 'runx' look at:  https://github.com/mviereck/runx" ;;
         --no-init|--openrc|--runit|--sysvinit|--tini)
                              error "Option ${1:-} has been removed.
  Please use option --init=INITSYSTEM instead." ;;
         --cachedir|--nothing|--no-xtest|--ps|--silent|--starter|--stderr|--stdout|--sys-admin|--trusted|--untrusted)
                              error "Option ${1:-} has been removed.
  Please have a look at 'x11docker --help' for possible replacements
  or search for '${1:-}' in /usr/share/doc/x11docker/CHANGELOG.md." ;;
  
     ##### Custom docker options / image name + container command. Everything after --
      --) 
        shift
        [ "$(cut -c1 <<< "${1:-}")"  = "-" ] && grep -q " -- "  <<< " $* " && {
          while [ $# -gt 0 ] ; do
            [ "${1:-}" = "--" ] && shift && break
            Customdockeroptions="$Customdockeroptions '${1:-}'"
            shift
          done
        }
        while [ $# -gt 0 ] ; do
          [ -n "${1:-}" ] && [ -z "$Imagename" ] && [ "$(echo "${1:-}" | cut -c1)"  = "-" ]  && Customdockeroptions="$Customdockeroptions ${1:-}"
          [ -n "${1:-}" ] && [ -z "$Imagename" ] && [ "$(echo "${1:-}" | cut -c1)" != "-" ]  && Imagename="${1:-}" && shift
          [ -n "${1:-}" ] && [ -n "$Imagename" ] && Containercommand="$Containercommand '${1:-}'"
          shift
        done
      ;;
      '') ;;
      *) error "Unknown option ${1:-}
  Parsed options:
  $Parsedoptions" ;;
    esac
    shift
  done
  
  Customdockeroptions="$(sed "s/--cap-add' '/--cap-add=/" <<< "$Customdockeroptions")"
  Customdockeroptions="$(sed "s/--runtime' '/--runtime=/" <<< "$Customdockeroptions")"
  grep -q -- "--runtime.kata"   <<< "$Customdockeroptions" && Runtime="kata-runtime"
  grep -q -- "--runtime.nvidia" <<< "$Customdockeroptions" && Runtime="nvidia"
  grep -q -- "--runtime.runc"   <<< "$Customdockeroptions" && Runtime="runc"
  grep -q -- "--runtime.crun"   <<< "$Customdockeroptions" && Runtime="crun"
  
  [ -n "$Xserver" ] && Autochooseserver="no"
  
  return 0
}