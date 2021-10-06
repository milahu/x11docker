declare_variables() {           # declare global variables
  export IFS=$' \n\t'                             # set IFS to default

  # Global environment variables used in x11docker
  ALSA_CARD=$(check_envvar "${ALSA_CARD:-}")
  CUPS_SERVER=$(check_envvar "${CUPS_SERVER:-}")
  DBUS_SESSION_BUS_ADDRESS=$(check_envvar "${DBUS_SESSION_BUS_ADDRESS:-}")
  DISPLAY=$(check_envvar "${DISPLAY:-}")
  DOCKER_HOST=$(check_envvar "${DOCKER_HOST:-}")
  GDK_BACKEND=$(check_envvar "${GDK_BACKEND:-}")
  HOME=$(check_envvar "${HOME:-}")
  LANG=$(check_envvar "${LANG:-}")
  LC_ALL=$(check_envvar "${LC_ALL:-}")
  PATH="$(check_envvar -w "${PATH:-}")"
  WAYLAND_DISPLAY=$(check_envvar "${WAYLAND_DISPLAY:-}")
  XAUTHORITY=$(check_envvar "${XAUTHORITY:-}")
  XDG_CURRENT_DESKTOP=$(check_envvar "${XDG_CURRENT_DESKTOP:-}")
  XDG_RUNTIME_DIR=$(check_envvar "${XDG_RUNTIME_DIR:-}")
  XDG_VTNR=$(check_envvar "${XDG_VTNR:-}")
  
  # Add possibly missing PATH entries
  PATH="${PATH:-"/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:/usr/local/games:/usr/games"}"
  grep -q ':/sbin:'            <<< ":$PATH:" || PATH="$PATH:/sbin"
  grep -q ':/usr/sbin:'        <<< ":$PATH:" || PATH="$PATH:/usr/sbin"
  grep -q ':/usr/local/bin:'   <<< ":$PATH:" || PATH="$PATH:/usr/local/bin"
  grep -q ':/usr/bin:'         <<< ":$PATH:" || PATH="$PATH:/usr/bin"
  grep -q ':/usr/local/games:' <<< ":$PATH:" || PATH="$PATH:/usr/local/games"
  grep -q ':/usr/games:'       <<< ":$PATH:" || PATH="$PATH:/usr/games"
  export PATH
  
  # File descriptors
  FDcmdstdin=""                                   # --stdin channel to forward stdin to container. Previously &7
  FDdockerstop=""                                 # message channel to send docker stop signal to dockerrc. Previously &4
  FDmessage=""                                    # message channel for notes, warnings and verbosity across threads and container. Previously &6
  #FDstderr=""                                    # internal stderr >&2, redirected to null with --silent. Already declared in main(). Previously &3
  FDtimetosaygoodbye=""                           # message channel to send termination signal from or to containers. Previously &8
  FDwatchpid=""                                   # message channel for watchpidlist(). Previously &9
  
  # Terminal colors used for messages and -V
  Esc="$(printf '\033')"
  Colblue="${Esc}[35m"
  Colyellow="${Esc}[33m"
  Colgreen="${Esc}[32m"
  Colgreenbg="${Esc}[42m"
  Colred="${Esc}[31m"
  Colredbg="${Esc}[41m"
  Coluline="${Esc}[4m"
  Colnorm="${Esc}[0m"
  
  # x11docker startup environment
  Runsinsnap=""                                   # docker runs in Ubuntu snap yes/no
  Runsinteractive=""                              # --enforce-i: Script runs in bash interactive mode (bash -i) yes/no.
  Runsinterminal=""                               # x11docker runs in a terminal yes/no
  Runsonconsole=""                                # x11docker runs on tty yes/no
  Runsoverssh=""                                  # x11docker runs over SSH yes/no. Makes a difference for --hostdisplay
  Runssourced=""                                  # x11docker has been sourced yes/no
  
  # Generated scripts
  Clipboardrc="clipboardrc"                       # --clipboard: Generated script for text clipboard sharing
  Cmdrc="cmdrc"                                   # Generated script starting container command
  Containerrc="containerrc"                       # Generated script starting cmdrc
  Containerrootrc="containerrootrc"               # Generated script to set up container, e.g. user creation. Runs as root in container.
  Dockerrc="dockerrc"                             # Generated script to check image, set up host and create $Containerrc
  Xinitrc="xinitrc"                               # Generated script to set up X, e.g. cookie and xrandr
  Xtermrc="xtermrc"                               # Generated script for password prompt
    
  # Internal messages
  Dockerstopsignalfifo="$Dockerrc.stopfifo"       # finish() send 'docker stop' signal to dockerrc
  Logmessages=""                                  # Stores messages until logfile is available, needed by logentry()
  Messagefifo="message.fifo"                      # Message channel for warning/verbose/debugnote/note/error within container, dockerrc, containerrootrc and others
  Storeinfofile="store.info"                      # File to store some info like id, pid, name, exit code
  Storepidfile="store.pids"                       # File to store pids and names of background processes that should be terminated on exit
  Timetosaygoodbyefile="timetosaygoodbye"         # File giving term signal to all parties
  Timetosaygoodbyefifo="timetosaygoodbye.fifo"    # Message channel for --init=openrc|runit|sysvinit to shut down on x11docker signal
  Usemkfifo=""                                    # Not on Windows nor with kata-runtime
  Watchpidfifo="watchpid.fifo"                    # Message channel to transfer pids to watchpidlist()
  X11dockererrorfile="x11docker.error"            # Store error exit code
  
  # Logfiles
  Compositorlogfile="compositor.log"              # Logfile for weston or kwin_wayland
  Containerlogfile="container.log"                # Logfile for container output other than container command output
  Logfile=""                                      # $Cachefolder/x11docker.log (current log)
  Logfilebackup=""                                # $Cachebasefolder/x11docker.log (latest terminated log)
  Messagelogfile="message.log"                    # Logfile for warning/verbose/debugnote/note/error
  Xinitlogfile="xinit.log"                        # Logfile for xinit/X server
  Xpraclientlogfile="xpra.client.log"             # Logfile for xpra client
  Xpraserverlogfile="xpra.server.log"             # Logfile for xpra server
    
  Dockercommandfile="docker.command"              # File to store generated docker command, needed for --interactive
  Dockerimagelistfile="docker.imagelist"          # File with list of local images.Used by x11docker-gui, too
  Dockerinfofile="docker.info"                    # File to store output of 'docker info'
  
  # Generated commands
  Compositorcommand=""                            # Command to start Weston or KWin
  Dockercommand=""                                # Command to run docker
  Xcommand=""                                     # Command to start X server
  Xpraclientcommand=""                            # xpra client command
  Xpraservercommand=""                            # xpra server command
  
  # Users
  Hostuser=""                                     # $Lognameuser or --hostuser. Unprivileged user for non-root commands. Compare unpriv()
  Hostusergid=""
  Hostuserhome=""
  Hostuseruid=""
  Containeruser=""                                # --user: Container user. Default: same as $Hostuser.
  Containeruseruid=""
  Containerusergid=""
  Containerusergroup=""
  Containerusergroups=""                          # --group-add: Additional groups for container user
  Containeruserhome=""                            # HOME path within container
  Containeruserhosthome=""                        # HOME path of container user on host
  Containeruserpassword=''
  Createcontaineruser="yes"                       # exception: --user=RETAIN
  Lognameuser=""                                  # $(logname) or $SUDO_USER or $PKEXEC_USER
  Passwordfile="$HOME/.config/x11docker/passwd"
  Persistanthomevolume=""                         # --home: Path to shared host folder or docker volume used as HOME in container.
  Startuser=""                                    # User who started x11docker
  Unpriv=""                                       # Command to run commands as unprivileged user
  Containerusershell="auto"                       # --shell: Preferred user shell
  
  # Hostsystem
  Hostarchitecture=""                             # uname -m, checked
  Hostcanwatchroot=""                             # x11docker can watch root processes yes/no. Related to $Hosthidepid
  Hostdisplay=""                                  # Environment variable DISPLAY
  Hostdisplaynumber=""                            # DISPLAY without : (and without possible IP)
  Hosthidepid=""                                  # /proc is mounted with hidepid=2 yes/no. Seen on NixOS.
  Hostip=""                                       # An IP address to access host. Preferred: IP of docker daemon
  Hostlibc=""                                     # glibc or musl. Can be important for locale and timezone.
  Hostlocaltimefile=""                            # Time zone from host, myrealpath /etc/localtime
  Hostmitshm="yes"                                # X on host has extension MIT-SHM enabled yes/no. Assume yes, check later
  Hostsystem=""                                   # $ID from /etc/os-release
  Hostutctime=""                                  # Time zone from host as offset to UTC
  Hostwaylandsocket="$WAYLAND_DISPLAY"            # Store host wayland socket name
  Hostxauthority="Xauthority.host.$(unspecialstring "${DISPLAY:-unknown}")"   # File to store copy of $XAUTHORITY
  Hostxenv=""                                     # Collection of host X environment variables
  Hostxsocket=""                                  # Socket of DISPLAY in /tmp/.X11-unix
  Nvidiacontainerfile="/usr/local/bin/NVIDIA-installer.run"  # --gpu: Path to nvidia installer in container
  Nvidiaversion=""                                # --gpu: Proprietary nvidia driver version on host
  Nvidiainstallerfile=""                          # --gpu: Proprietary nvidia driver installer for container in [...]local/share/x11docker
  Pythonbin=""                                    # path to python binary
  
  # MS Windows
  Winpty=""                                       # Path to winpty for --interactive on MS Windows
  Winsubmount=""                                  # Path within subsystem to mounted MS Windows drives
  Winsubpath=""                                   # Path within MS Windows to subsystem files
  Winsubsystem=""                                 # MS Windows subsystem WSL1, WSL2, MSYS2 or CYGWIN
  Mobyvm=""                                       # MS Windows: Use MobyVM yes/no (No only for WSL2 possible)
  
  # Cache folders
  Cachebasefolder=""                              # --cachebasedir Base cache folder
  Cachefolder=""                                  # Subfolder of $Cachebasefolder for current container
  Sharefolder="share"                             # Subfolder of $Cachefolder for cache files shared with container
  Sharefoldercontainer="/x11docker"               # Mountpoint of $Sharefolder in container
  
  # stdin stdout stderr
  Cmdstdinfifo="stdin"                            # stdin for container command. fifo/named pipe to forward stdin of x11docker to container command
  Cmdstderrlogfile="stderr"                       # stderr for container command
  Cmdstdoutlogfile="stdout"                       # stdout for container command
  Forwardstdin="no"                               # --stdin: forward stdin to container command yes/no

  # X and Wayland configuration
  Autochooseserver="yes"                          # --auto: automatic choice of X server (default)
  Cleanxhost="no"                                 # --clean-xhost: remove xhost access policies on host X
  Compositorerrorcodes="Failed to process Wayland|failed to create display|] fatal:"
  Desktopmode="no"                                # --desktop: image contains a desktop environment.
  Dpi=""                                          # --dpi: dots per inch. Influences font size
  Fullscreen="no"                                 # --fullscreen: Fullscreen mode
  Iglx=""                                         # --iglx: Enable indirect rendering yes/no/""
  Lastcheckedxserver=""                           # check_xdepends(): Last X server option that was checked
  Lastcheckedxserverresult=""                     # check_xdepends(): Result of last check. Avoids double-checking.
  Maxxaxis=""                                     # Maximal X screen size of display
  Maxyaxis=""                                     # Maximal Y screen size of display
  Modelinefilebasepath="modelines"
  Newdisplay=""                                   # --display: New DISPLAY for new X server
  Newdisplaynumber=""                             # --display: New display number for new X server.
  Newwaylandsocket=""                             # Wayland socket of $Compositorcommand
  Newxenv=""                                      # Environment variables for new X server: DISPLAY XAUTHORITY XSOCKET WAYLAND_DISPLAY
  Newxlock=""                                     # .Xn-lock - exists for running X server with socket n
  Newxsocket=""                                   # New X unix socket
  Newxvt=""                                       # --vt: number of virtual console to use for --xorg
  Numbersinusefile="displaynumbers.$(date +%y_%m_%d)" # File to store display numbers used today. Helps to avoid race conditions on simultaneous startups
  Nxagentclientrc="nxagent.nxclientrc"            # --nxagent NX_CLIENT script to catch nxagent messages
  Nxagentkeysfile="nxagent.keys"                  # --nxagent keyboard shortcut config
  Nxagentoptionsfile="nxagent.options"            # --nxagent options not available on cli, but possible in config file
  Modeline=""                                     # Screen modeline describing display size, see "man cvt". Needed for Xdummy
  Outputcount="1"                                 # --output-count: quantum of virtual screens for Weston or Xephyr
  Rotation=""                                     # --rotate: Rotation for --weston, --weston-xwayland or --xorg: 0/90/180/270/flipped/flipped-90/..
  Scaling=""                                      # --scale: Scaling factor for xpra and weston
  Screensize=""                                   # --size XxY: Display size
  Setupwayland="no"                               # --wayland, --kwin, --weston --hostwayland: Provide a Wayland environment
  Trusted="yes"                                   # Create trusted or untrusted cookies,  --hostdisplay uses untrusted cookies by default
  Waylandtoolkitenv="XDG_SESSION_TYPE=wayland GDK_BACKEND=wayland QT_QPA_PLATFORM=wayland CLUTTER_BACKEND=wayland SDL_VIDEODRIVER=wayland ELM_DISPLAY=wl ELM_ACCEL=opengl ECORE_EVAS_ENGINE=wayland_egl"
  Waylandtoolkitvars="XDG_SESSION_TYPE GDK_BACKEND QT_QPA_PLATFORM CLUTTER_BACKEND SDL_VIDEODRIVER ELM_DISPLAY ELM_ACCEL ECORE_EVAS_ENGINE"
  Xauthentication="yes"                           # --no-auth: use cookie authentication and disable xhost yes/no
  Xaxis=""                                        # Virtual screen width
  Xcomposite=""                                   # --xcomposite: +extension COMPOSITE yes/no
  Xkblayout=""                                    # --keymap: Layout for keymap, compare /usr/share/X11/xkb/symbols
  Xfishtank="no"                                  # --xfishtank: Show a fish tank on new X server
  Xhost=""                                        # --xhost: custom xhost setting on new X server
  Xiniterrorcodes="xinit: giving up|unable to connect to X server|Connection refused|server error|Only console users are allowed"
  Xlegacywrapper=""                               # --xorg: /etc/X11/Xwrapper.config is configured to run within X yes/no
  Xpraborder=""                                   # --border: Colored border for xpra clients
  Xpracontainerenv="UBUNTU_MENUPROXY= QT_X11_NO_NATIVE_MENUBAR=1 MWNOCAPTURE=true MWNO_RIT=true MWWM=allwm GTK_OVERLAY_SCROLLING=0 GTK_CSD=0 NO_AT_BRIDGE=1" # environment variables 
  Xprahelp=""                                     # Output of 'xpra --help'
  Xprarelease=""                                  # Release number from $Xpraversion
  Xprashm=""                                      # Content XPRA_XSHM=0 disables usage of MIT-SHM in xpra
  Xpraversion=""                                  # $(xpra --version) to decide some xpra options and messages
  Xpravfb=""                                      # --xpra, --xdummy, --xvfb: vfb for --xpra: Xdummy or Xvfb
  Xserver=""                                      # X server option to use
  Xoverip=""                                      # --xoverip: Connect to X over TCP yes/no
  Xserveroptions=""                               # --xopt: Custom X server options
  Xtest=""                                        # --xtest: Enable extension Xtest yes/no. If empty, yes for --xpra/--xdummy/--xvfb, otherwise no
  Yaxis=""                                        # Virtual screen height
  
  # X and Wayland config and cookie files
  Customwestonini=""                              # --westonini: Custom config file for weston
  Westonini="weston.ini"                          # Generated config file for weston
  Xdummyconf="xorg.xdummy.conf"                   # --xdummy, --xpra: Generated xorg.conf for dummy video driver
  Xclientcookie="Xauthority.client"               # Generated X client cookie. Normally same as $Xservercookie, except for --hostdisplay and --nxagent
  Xkbkeymapfile="xkb.keymap"                      # --keymap: File to store output of host keymap in xinitrc
  Xorgconf=""                                     # --xorgconf: custom xorg.conf
  Xservercookie="Xauthority.server"               # Generated X server cookie
  Xorgwrapper="Xorg.xdummy.wrapper"               # --xpra, --xdummy: Fork from xpra to wrap Xorg for Xdummy
  
  # Window manager
  Windowmanagermode="none"                        # --wm: Window manager to use: container/host/auto
  Windowmanagercommand=""                         # --wm: Argument for --wm or host wim command
  
  # Host integration
  Alsacard="$ALSA_CARD"                           # --alsa: Specified ALSA card
  Hosthomebasefolder=""                           # --homebasedir: Base directory for container home with --home
  Langwunsch=""                                   # --lang: Search or create UTF-8 locale in container and set LANG
  Pulseaudioconf="pulseaudio.client.conf"         # --pulseaudio: Client config in container
  Pulseaudiocookie="pulseaudio.cookie"            # --pulseaudio: possible pulse cookie from host to share
  Pulseaudiomode=""                               # --pulseaudio: 'tcp', 'socket' or 'auto'
  Pulseaudiomoduleid=""                           # --pulseaudio: module ID, stored for unload in finish()
  Pulseaudioport=""                               # --pulseaudio: TCP port for --pulseaudio=tcp
  Pulseaudiosocket="pulseaudio.socket"            # --pulseaudio: unix socket for --pulseaudio=socket
  Sharealsa="no"                                  # --alsa: enable ALSA sound, share /dev/snd
  Shareclipboard="no"                             # --clipboard: Enable clipboard sharing
  Sharecupsmode=""                                # --printer: Share access to CUPS printer server: socket|tcp|""
  Sharegpu="no"                                   # --gpu: Use hardware accelerated OpenGL, share files in /dev/dri
  Sharehome="no"                                  # --home: Share a folder ~/.local/share/x11docker/Imagename with created container
  Sharevolumes=""                                 # --share: Host files or folders or devices to share, array
  Sharevolumescount="0"                           # --share: Counts shared folders in array
  Sharewebcam="no"                                # --webcam: Share webcam device /dev/video*
  
  # Container setup
  Adminusercaps="no"                              # --cap-default, --sudouser, --user=root, --init=systemd: add capabilities for general container system administration
  Allownewprivileges="auto"                       # --newprivileges: Docker run option --security-opt=no-new-privileges. Default: no. Enabled by options --newprivileges, --cap-default, --sudouser and --user=root.
  Capabilities=""                                 # Capabilities to add. Default: none, exceptions for --init, --sudouser
  Capdropall="yes"                                # --cap-default: Drop all container capabilities and set --securty-opt=no-new-privileges yes/no
  Containerbackend="docker"                       # --backend: Backend to use, like docker, podman, nerdctl, udocker
  Containerbackendbin=""                          # path to binary of backend
  Containercommand=""                             # Container command [+args]
  Containerenvironment=""                         # --env: Environment variables
  Containerenvironmentcount="0"
  Containerenvironmentfile="container.environment" # file to store final container environment
  Containerlocaltimefile="libc.localtime"         # localtime file from host shared to container
  Containername=""                                # --name: Container name
  Containersetup="yes"
  Customdockeroptions=""                          # -- [...] -- : Custom options for "docker run".
  Rootlessbackend=""                               # Check for rootful/rootless docker depending on DOCKER_HOST
  Imagename=""                                    # Image to run
  Interactive="no"                                # --interactive: Run docker with interactive tty yes/no
  Limitresources=""                               # --limit: Limit access to CPU and RAM, 0.1 ... 1.0
  Network=""                                      # --network
  Noentrypoint="no"                               # --no-entrypoint: Disable entrypoint in image yes/no
  Runtime=""                                      # Runtime to use. runc|nvidia|kata-runtime|crun
  Snapsupport=""                                  # --snap: Fallback mode to support docker in snap
  Sharehostipc="no"                               # --hostipc: Set --ipc=host.
  Stopsignal=""                                   # Signal to send on 'docker stop'
  Sudouser=""                                     # --sudouser: Create user with sudo permissions and root user with password 'x11docker'
  Switchcontaineruser="no"                        # --init=systemd|openrc|runit|sysvinit: User switching to trigger login services yes/no
  Switchcontainerusercaps="no"                    # --init=systemd|openrc|runit|sysvinit, --sudouser, --user=root: Add capabilities for su/sudo user switching
  Systemdconsoleservice="systemd.console-getty.service" # --init=systemd
  Systemdenvironment="systemd.environment.conf"
  Systemdjournallogfile="systemd.journal.log"
  Systemdjournalservice="systemd.journal.service"
  Systemdtarget="systemd.x11docker.target"
  Systemdwatchservice="systemd.watch.service"
  Workdir=""                                      # --workdir: Set working directory in container

  # Init and DBus
  Dbusrunsession="no"                             # --dbus, --wayland, --init=systemd|openrc|runit|sysvinit: Run container command with dbus-run-session / DBus user session
  Dbussystem="no"                                 # --init=systemd|openrc|runit|sysvinit: Run DBus system daemon in container
  Initsystem="tini"                               # --init: Init system in container
  Sharecgroup="no"                                # --sharecgroup, --init=systemd: share /sys/fs/cgroup. Also needed for elogind
  Sharehostdbus="no"                              # --hostdbus: Connect to DBus user daemon on host
  Tinibinaryfile=""                               # --init=tini (default): Binary of tini; either /usr/bin/docker-exec or provided by user in [...]/share/x11docker
  Tinicontainerpath="/usr/local/bin/init"         # --init=tini: Path of tini (or catatonit) in container
  
  # Gaining root privileges to run docker
  Passwordcommand=""                              # --pw: Generated command for password prompt
  Passwordfrontend=""                             # --pw: Frontend for password. One of pkexec, su, sudo, gksu, gksudo, kdesu, kdesudo, lxsu, lxsudo, beesu, auto, none
  Passwordneeded="yes"                            # Password needed to run docker? assume yes, check later
  Sudo=""                                         # "sudo", "sudo -n", or empty. Added as prefix to some privileged commands, especially docker.
  
  # Custom additional commands
  Runasuser=""                                       # --runasuser: Add container command to containerrc
  Runasroot=""                                    # --runasroot: Add container command to container setup script running as root
  Runfromhost=""                                  # --runfromhost: Add host command to xinitrc
  
  # Miscellaneous
  Buildimage=""                                   # --build: x11docker image to build from repo Dockerfile
  Cachenumber="$(date +%s%N | cut -c6-16)"        # Number to use for cache folder
  [ -z "$Cachenumber" ] && Cachenumber="$(makecookie)"
  Codename=""                                     # created from image name and command without special chars for use with container name and cache folder
  Fallback="yes"                                  # --fallback: Allow or deny fallbacks for failing options.
  Hostexe=""                                      # --exe: Host command
  Imagebasename=""                                # Image name without tags and / replaced with -. For use of --home folders.
  Parsedoptions_global=""                         # Parsed options
  Passwordterminal=""                             # Terminal emulator to use for password prompt (if no terminal emulator is needed, it will be 'bash -c')
  Presetdirlocal="$HOME/.config/x11docker/preset"
  Presetdirsystem="/etc/x11docker/preset"
  Preservecachefiles="no"                         # If yes, don't delete cache files on exit. For few failure cases only.
  Pullimage="ask"                                 # --pull: Allow 'docker pull' yes|no|always|ask
  X11dockermode="run"                             # --exe, --xonly: Can be either "run" (default), "exe", or "xonly".
  
  # Verbosity options
  Debugmode="no"                                  # --debug: Excerpt of --verbose, also bash error checks
  Showcache="no"                                  # --showcache: Output of $Cachefolder on stdout (x11docker-gui only)
  Showcontainerid="no"                            # --showid: Output of container ID on stdout
  Showcontaineroutput="yes"                                # Show container command stdout
  Showcontainerpid1pid="no"                       # --showpid1: Output of host PID of container PID 1 on stdout
  Showdisplayenvironment="no"                     # --showenv: Output of environment variables of new display on stdout
  Showinfofile="no"                               # --showinfofile: Show path of $Storeinfofile
  Silent="no"                                     # --quiet: Do not show x11docker messages
  Verbose="no"                                    # --verbose: Be verbose yes/no
  Verbosecolors="no"                              # -V: colored output for --verbose (and delete some noisy systemd error messages)
  Wikipackages="You can look for the package name of this command at: 
 https://github.com/mviereck/x11docker/wiki/dependencies#table-of-all-packages"
  
  # Special options not starting X or docker
  Cleanup="no"                                    # --cleanup: Remove orphaned containers and cache files
  Createlauncher="no"                             # --launcher: Create application launcher on desktop and exit yes/no
  Installermode=""                                # --install/--update/--update-master/--remove
  
  # Lists of window managers
  # - these window managers are known to work well with x11docker (alphabetical order)(excluding $Wm_not_recommended and $Wm_ugly):
  Wm_good="amiwm blackbox cinnamon compiz ctwm enlightenment fluxbox flwm fvwm"
  Wm_good="$Wm_good jwm kwin kwin_x11 lxsession mate-session mate-wm marco metacity notion olwm olvwm openbox ororobus pekwm"
  Wm_good="$Wm_good sawfish twm wmaker w9wm xfwm4"
  # - these wm's are recommended and lightweight, but cannot show desktop options. best first:
  Wm_recommended_nodesktop_light="xfwm4 metacity marco openbox sawfish"
  # - these wm's are recommended and heavy, but cannot show desktop options (especially exiting themselves). best first:
  Wm_recommended_nodesktop_heavy="kwin compiz"
  # - these wm's are recommended, lightweight AND desktop independent. best first:
  Wm_recommended_desktop_light="flwm blackbox fluxbox jwm mwm wmaker afterstep amiwm fvwm ctwm pekwm olwm olvwm openbox"
  # - these wm's are recommended, heavy AND desktop independent. best first:
  Wm_recommended_desktop_heavy="lxsession mate-session enlightenment cinnamon cinnamon-session plasmashell"
  # - these wm's are not really useful (please don't hit me) (best first):
  Wm_not_recommended="awesome evilwm herbstluftwm i3 lwm matchbox miwm mutter spectrwm subtle windowlab wmii wm2"
  # - these wm's cannot be autodetected by wmctrl if they are already running
  Wm_nodetect="aewm aewm++ afterstep awesome ctwm mwm miwm olwm olvwm sapphire windowlab wm2 w9wm"
  # - these wm's can cause problems (they can be beautiful, though):
  Wm_ugly="icewm sapphire aewm aewm++"
  # - these wm's doesn't work:
  Wm_bad="budgie-wm clfswm tinywm tritium muffin gnome-shell"
  # List of all working window managers, recommended ones first, excluding $Wm_bad:
  Wm_all="$Wm_recommended_nodesktop_light $Wm_recommended_nodesktop_heavy  $Wm_recommended_desktop_light $Wm_recommended_desktop_heavy $Wm_good $Wm_ugly $Wm_not_recommended $Wm_nodetect"

  # x11docker communication functions to integrate into generated scripts
  Messagefifofuncs='
warning() {
  echo "$*:WARNING"   | sed "s/\$/ /" >>$Messagefile
}