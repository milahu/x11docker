usage() {                       # --help: show usage information
  echo "
x11docker: Run GUI applications and desktop environments in containers.
           Supports docker, podman and nerdctl.

Usage:
To run a container on a new X server:
  x11docker IMAGE
  x11docker [OPTIONS] IMAGE [COMMAND]
  x11docker [OPTIONS] -- IMAGE [COMMAND [ARG1 ARG2 ...]]
  x11docker [OPTIONS] -- RUN_OPTIONS -- IMAGE [COMMAND [ARG1 ARG2 ...]]
To run a host application on a new X server:
  x11docker [OPTIONS] --exe COMMAND
  x11docker [OPTIONS] --exe -- COMMAND [ARG1 ARG2 ...]
To run only an empty new X server:
  x11docker [OPTIONS] --xonly
  
x11docker always runs a fresh container from image and discards it afterwards.
Runs on Linux and (with some restrictions) on MS Windows. Not adapted for macOS.

Optional features:
  * GPU hardware acceleration
  * Sound with pulseaudio or ALSA
  * Clipboard sharing
  * Printer access
  * Webcam access
  * Persistent home folder
  * Wayland support
  * Language locale creation
  * Several init systems and DBus in container
  * Support of several container runtimes
Focus on security:
  * Avoids X security leaks using additional X servers.
  * Container user is same as host user to avoid root in container.
  * Restricts container capabilities to bare minimum.
To switch between docker, podman and nerdctl use option --backend.

x11docker sets up an unprivileged container user with password 'x11docker'
and restricts container capabilities. Some applications might behave different
than with a regular 'docker run' command due to these security restrictions.
Achieve a less restricted setup with --cap-default, --sudouser or --user=root.

Dependencies on host:
  For core functionality x11docker only needs bash, an X server and one of
  docker, podman or nerdctl.
  Depending on chosen options x11docker might need some additional tools.
  It checks for them on startup and shows messages if some are missing.
  Core list of recommended tools:
   * Recommended to allow security and convenience:
       X servers: xpra Xephyr nxagent 
       X tools:   xauth xclip xrandr xhost xinit
   * Advanced GPU support: weston Xwayland xpra xdotool
  See also: https://github.com/mviereck/x11docker/wiki/Dependencies

Dependencies in image:
  No dependencies in image except for a few feature options. Most important:
   --gpu:  OpenGL/MESA packages, collected often in 'mesa-utils' package.
   --pulseaudio: Needs pulseaudio on host and pulseaudio client libs in image.
   --printer: Needs cups on host and cups client libs in image.
  See also: https://github.com/mviereck/x11docker/wiki/Dependencies
  
Options: (short options do not accept arguments)
     --help            Display this message and exit.
 -e, --exe             Execute host application instead of a container.
     --license         Show license of x11docker (MIT) and exit.
     --version         Show x11docker version and exit.
     --xonly           Only start empty X server.

Basic settings:
 -d, --desktop         Indicate a desktop environment in image.
                       In that case important for automatic X server choice.
 -i, --interactive     Run with an interactive tty to allow shell commands.
                       Useful with commands like bash.

Host integration:
     --alsa [=ALSA_CARD]  Sound with ALSA. You can define a desired sound card
                       with ALSA_CARD. List of available sound cards: aplay -l
 -c, --clipboard       Share clipboard. Graphical clips with --xpra only.
 -g, --gpu             GPU access for hardware accelerated OpenGL rendering. 
                       Works best with open source drivers on host and in image.
                       For closed source nvidia drivers regard terminal output.
 -I, --network [=NET]  Allow internet access. (Currently enabled by default,
                       will change in future.)
                       For optional argument NET see Docker documentation
                       of docker run option --network.
                       --network=none disables internet access. (future default)
 -l, --lang [=LOCALE]  Set language variable LANG=LOCALE in container.
                       Without arg LOCALE host variable --lang=\$LANG is used.
                       If LOCALE is missing in image, x11docker generates it
                       with 'localedef' in container (needs 'locales' package).
                       Examples for LOCALE: ru, en, de, zh_CN, cz, fr, fr_BE.
 -P, --printer [=MODE] Share host printers through CUPS server.
                       Optional MODE can be 'socket' or 'tcp'. Default: socket
 -p, --pulseaudio [=MODE]  Sound with pulseaudio. Needs 'pulseaudio' on host
                       and in image. Optional arg MODE can be 'socket' or 'tcp'.
     --webcam          Share host webcam device files.

Shared host folders or volumes:
 -m, --home [=ARG]     Create a persistent HOME folder for data storage.
                       Default: Uses ~/.local/share/x11docker/IMAGENAME.
                       ARG can be another host folder or a volume.
                       (~/.local/share/x11docker has a softlink to ~/x11docker.)
                       (Use --homebasedir to change this base storage folder.)
     --share=ARG       Share host file or folder ARG. Read-only with ARG:ro
                       Device files in /dev can be shared, too.
                       ARG can also be a volume instead of a host folder.

X server options:
     --auto            Automatically choose X server (default). Influenced
                       notably by options --desktop, --gpu, --wayland, --wm.
 -h, --hostdisplay     Share host display :0. Quite bad container isolation!
                       Least overhead of all X server options.
                       Some apps may fail due to restricted untrusted cookies.
                       Remove restrictions with option --clipboard.
 -n, --nxagent         Nested X server supporting seamless and --desktop mode.
                       Faster than --xpra, but can have compositing issues.
 -Y, --weston-xwayland Desktop mode like --xephyr, but supports option --gpu.
                       Runs from console, within X and within Wayland.
 -y, --xephyr          Nested X server for --desktop mode. Without --desktop
                       a host window manager will be provided (option --wm).
 -x, --xorg            Core Xorg server. Runs ootb from console.
                       Switch tty with <CTRL><ALT><F1>....<F12>. Always switch
                       to a black tty before switching to X to avoid crashes.
 -a, --xpra            Nested X server supporting seamless and --desktop mode.
 -A, --xpra-xwayland   Like --xpra, but supports option --gpu.

Special X server options:
     --kwin-xwayland   Like --weston-xwayland, but using kwin_wayland
 -t, --tty             Terminal only mode. Does not run an X or Wayland server.
     --xdummy          Invisible X server using dummy video driver.
     --xvfb            Invisible X server using Xvfb.
                       --xdummy and --xvfb can be used for custom  VNC access.
                       Output of environment variables on stdout. (--showenv)
                       Along with option --gpu an invisible setup with Weston,
                       Xwayland and xdotool is used (instead of Xdummy or Xvfb).
 -X, --xwayland        Blanc Xwayland, needs a running Wayland compositor.
     --xwin            X server to run in Cygwin/X on MS Windows.

Wayland instead of X:
 -W, --wayland         Automatically set up a Wayland environment.
                       Chooses one of following options and regards --desktop.
 -T, --weston          Weston without X for pure Wayland applications.
                       Runs in X, in Wayland or from console.
 -K, --kwin            KWin without X for pure Wayland applications.
                       Runs in X, in Wayland or from console.
 -H, --hostwayland     Share host Wayland without X for pure Wayland apps.

X and Wayland appearance options:
     --border [=COLOR] Draw a colored border in windows of --xpra[-xwayland].
                       Argument COLOR can be e.g. 'orange' or '#F00'. Thickness
                       can be specified, too, e.g. 'red,3'. Default: 'blue,1'
     --dpi=N           dpi value (dots per inch) to submit to X clients.
                       Influences font size of some applications.
 -f, --fullscreen      Run in fullscreen mode.
     --output-count=N  Multiple virtual monitors for Weston, KWin or Xephyr.
     --rotate=N        Rotate display (--xorg, --weston and --weston-xwayland)
                       Allowed values: 0, 90, 180, 270, flipped, flipped-90,
                       flipped-180, flipped-270.  (flipped means mirrored)
     --scale=N         Scale/zoom factor N for xpra, Xorg or Weston.
                       Allowed for --xpra, --xorg --xpra-xwayland: 0.25...8.0.
                       Allowed for --weston and --weston-xwayland: 1...9.
                       (Mismatching font sizes can be adjusted with --dpi).
                       Odd resolutions with --xorg might need --scale=1.
     --size=WxH        Screen size of new X server (e.g. 800x600).
 -w, --wm [=ARG]       Provide a host window manager to container applications.
                       Possible ARG:
                         host: autodetection of a host window manager.
                         COMMAND: command of a desired host window manager.
                         none: Run without a window manager. Same as --desktop.
 -F, --xfishtank       Show fish tank on new X server.

X and Wayland special configuration:
     --clean-xhost     Disable xhost access policies on host display.
     --composite [=yes|no]  Enable or disable X extension Composite.
                       Default is yes except for --nxagent. Can cause or
                       fix issues with some applications on nxagent.
     --display=N       Use display number N for new X server.
     --iglx            Use indirect rendering for OpenGL. (Currently works with
                       closed source nvidia driver only, bug in MESA libgl.)
     --keymap=LAYOUT   Set keyboard layout for new X server, e.g. de, us, ru.
                       For possible LAYOUT look at /usr/share/X11/xkb/symbols.
     --no-auth         Allow access to X for everyone. Security risk!
     --vt=N            Use vt / tty N (regarded by --xorg only).
     --westonini=FILE  Custom weston.ini for --weston and --weston-xwayland.
     --xhost [=STR]    Set \"xhost STR\" on new X server (see 'man xhost').
                       Without STR will set:  +SI:localuser:\$USER
                       (Use with care. '--xhost +' allows access for everyone).
     --xoverip         Connect to X over TCP network. For special setups only.
                       Only supported by a subset of X server options.
     --xtest [=yes|no] Enable or disable X extension XTEST. Default is yes for
                       --xpra, --xvfb and --xdummy, no for other X servers.
                       Needed to allow custom access with xpra. 

Container user settings:
     --group-add=GROUP Add container user to group GROUP.
     --hostuser=USER   Run X (and container user) as user USER. Default is
                       result of \$(logname). (x11docker must run as root).
     --password [=WORD]   Change container user password and exit.
                       Interactive input if argument WORD is not provided.
                       Stored encrypted in ~/.config/x11docker/passwd.
     --sudouser [=nopasswd] Allow su and sudo for container user. Use with care,
                       severe reduction of default x11docker security!
                       Optionally passwordless sudo with argument nopasswd.
                       Default password is 'x11docker'.
     --user=N          Create container user N (N=name or N=uid). Default:
                       same as host user. N can also be an unknown user id.
                       You can specify a group id with N being 'user:gid'.
                       Special case: --user=RETAIN keeps image user settings.

Container capabilities:
  In most setups x11docker sets --cap-drop=ALL --security-opt=no-new-privileges
  and shows warnings if doing otherwise.
  Custom capabilities can be added with --cap-add=CAP after  --
     --cap-default     Allow default container capabilities.
                       Includes --newprivileges=yes.
     --hostipc         Sets run option --ipc=host. Disables IPC namespacing.
                       Severe reduction of container isolation! Shares
                       host interprocess communication and shared memory.
                       Allows MIT-SHM extension of X servers.
     --limit [=FACTOR] Limit CPU and RAM usage of container to 
                       currently free RAM x FACTOR and available CPUs x FACTOR.
                       Allowed range is 0 < FACTOR <= 1. 
                       Default for --limit without argument FACTOR: 0.5
     --newprivileges [=yes|no|auto]  Set or unset run option 
                       --security-opt=no-new-privileges. Default with no
                       argument is 'yes'. Default for most cases is 'no'.

Container init system, elogind and DBus daemon:
     --dbus [=system]  Run DBus user session daemon for container command.
                       With argument 'system' also run a DBus system daemon. 
                       (To run a DBus system daemon rather use one of 
                        --init=systemd|openrc|runit|sysvinit )
     --hostdbus        Connect to DBus user session from host.
     --init [=INITSYSTEM] Run an init system as PID 1 in container. Solves the
                       zombie reaping issue. INITSYSTEM can be:
                         tini: Default. Mostly present as docker-init on host.
                         none: No init system, container command will be PID 1.
                       Others: systemd, sysvinit, runit, openrc, s6-overlay.
     --sharecgroup     Share /sys/fs/cgroup. Allows elogind in container if
                       used with one of --init=openrc|runit|sysvinit

Container special configuration:
     --backend=BACKEND   Container backend to use: docker, podman or nerdctl.
                       Default: docker.
                       For rootless mode podman is recommended.
                       For rootful podman or nerdctl use sudo or option --pw.
                       For rootless docker set DOCKER_HOST accordingly.
                       Rootless docker and rootless nerdctl do not support
                       option --home and work not well with option --share.
     --env VAR=value   Set custom environment variable VAR=value
     --name=NAME       Specify container name NAME.
     --no-entrypoint   Disable ENTRYPOINT in image to allow other commands, too
     --no-setup        No x11docker setup in running container. Disallows
                       several other options. See also --user=RETAIN.
     --runtime=RUNTIME  Specify container runtime. Known by x11docker:
                         runc:         Docker default runtime.
                         crun:         Fast replacement for runc written in C.
                         nvidia:       Runtime for nvidia/nvidia-docker images.
                         kata-runtime: Runtime using a QEMU VM.
     --shell=SHELL     Set preferred user shell. Example: --shell=/bin/zsh
     --snap            Enable support for Docker in snap.
     --stdin           Forward stdin of x11docker to container command.
     --workdir=DIR     Set working directory DIR.
     
Additional commands: (You might need to move them to background with 'CMD &'.)
     --runasroot=CMD   Run command CMD as root in container.
     --runasuser=CMD   Run command CMD with user privileges in container 
                       before running image command.
     --runfromhost=CMD Run host command CMD on new X server.

Miscellaneous:
     --build IMAGE     Build an image from a Dockerfile from x11docker 
                       repository. Example: 'x11docker --build x11docker/fvwm'
                       Works for all repositories beginning with 'dockerfile'
                       at https://github.com/mviereck?tab=repositories
                       Regards (only) option --backend=BACKEND.
     --cachebasedir=DIR  Custom base folder for cache files.
     --homebasedir=DIR   Custom base folder for option --home.
     --enforce-i       Run x11docker in interactive bash mode to allow tty 
                       access. Can help to run weston-launch on special systems.
     --fallback [=yes|no]  Allow or deny fallbacks if a chosen option cannot
                       be fulfilled. By default fallbacks are allowed.
     --launcher        Create application launcher with current options
                       on desktop and exit. You can get a menu entry moving
                       the created .desktop file to ~/.local/share/applications
     --mobyvm          Use MobyVM (for WSL2 only that defaults to Linux Docker).
     --preset=FILE     Read a set of predefined options stored in file FILE.
                       Useful to shortcut often used option combinations.
                       FILE is searched in directory /etc/x11docker/preset,
                       or in directory ~/.config/x11docker/preset or absolute.
                       Multiple lines in FILE are allowed.
                       Comment lines must begin with #
     --pull [=ask|yes|no|always]  Behaviour if image is missing on host.
                       ask: Ask in terminal, timeout after 60s (default).
                       yes: Allow docker pull (default for --pull without arg).
                       no: Do not run or ask for 'docker pull'
                       always: Always run 'docker pull'. Download only if
                       newer image is available. Allows sort of auto-update.
     --pw [=FRONTEND]  Choose frontend for password prompt. Possible FRONTEND:
                         su sudo gksu gksudo lxsu lxsudo kdesu kdesudo
                         pkexec beesu none
                       If FRONTEND is not specified, one of sudo or su is used.
                       This allows to choose between rootful or rootless mode
                       of nerdctl and podman.
     
Output of parseable information on stdout:
  Get output e.g. with:  read xenv < <(x11docker --showenv x11docker/check)
     --showenv         Print new \$DISPLAY, \$XAUTHORITY and \$WAYLAND_DISPLAY.
     --showid          Print container ID.
     --showinfofile    Print path to internal x11docker info storage file.
     --showpid1        Print host PID of container PID 1.

Verbosity options:
 -D, --debug           Debug mode: Show some less verbose debug output
                       and enable rigorous error control.
 -q, --quiet           Suppress x11docker terminal messages.
 -v, --verbose         Be verbose. Output of x11docker.log on stderr.
 -V                    Be verbose with colored output. 

Installation options and cleanup (need root permissions):
     --install         Install x11docker and x11docker-gui from current folder.
                       Useful to install from an extracted zip file.
     --update          Download and install latest release from github.
     --update-master   Download and install latest master version from github.
     --remove          Remove x11docker from your system. Includes --cleanup.
                       Preserves ~/.local/share/x11docker from option --home.
     --cleanup         Clean up orphaned containers and cache files.
                       Terminates currently running x11docker containers, too.
                       Regards (only) option --backend=BACKEND.
--update, --update-master and --remove regard a possible custom installation
path different from default /usr/bin directory. 
Additional options are disregarded.

Exit codes:
  0:     Success
  64:    x11docker error
  130:   Terminated by ctrl-c
  other: Exit code of command in container

x11docker version: $Version
Please report issues and get help at: https://github.com/mviereck/x11docker
"
}