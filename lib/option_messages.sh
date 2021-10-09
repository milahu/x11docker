option_messages() {             # some messages depending on options, but not changing settings
  # X server specific messages
  case $Xserver in
    --hostdisplay)
      [ "$Autochooseserver" = "yes" ] && [ -z "$Winsubsystem" ] && case "$Sharegpu" in
        yes)
          case $Nvidiaversion in
            "") note "To allow protection against X security leaks,
  please install 'xinit' and one or more of:
    xpra, weston+Xwayland or kwin_wayland+Xwayland,
  or run a second Xorg server with option --xorg." ;;
            *) note "To allow protection against X security leaks 
  while using --gpu with NVIDIA, please use option --xorg." ;;
          esac
        ;;
        no) note "To allow protection against X security leaks,
  please install 'xinit' and one or more of:
    xpra, Xephyr, nxagent, weston+Xwayland, kwin_wayland+Xwayland or Xnest,
  or run a second Xorg server with option --xorg." ;;
      esac
      case "$Trusted" in
        no)
          warning "Option --hostdisplay provides only low container isolation!
  It is recommended to use another X server option like --nxagent or --xpra.

  To improve security with --hostdisplay x11docker uses untrusted cookies.
  This can lead to strange behaviour of some applications.

  If you encounter application ${Colredbg}errors${Colnorm}, enable option --clipboard
  that disables security restrictions for --hostdisplay as a side effect." ;;
        yes)
          case $Winsubsystem in
            "") warning "Option --hostdisplay with trusted cookies provides
      QUITE BAD CONTAINER ISOLATION !
  Keylogging and controlling host applications is possible! 
  Clipboard sharing is enabled (option --clipboard).
  It is recommended to use another X server option like --nxagent or --xpra." ;;
            MSYS2) ;;
            CYGWIN) warning "Option --hostdisplay allows less security hardening.
  It is recommended to use option --xwin instead." ;;
            WSL1|WSL2) warning "Option --hostdisplay allows less security hardening.
  It is recommended to use another X server option like --nxagent or --xephyr." ;;
          esac
        ;;
      esac
      [ "$Desktopmode" = "yes" ] && note "Can not avoid to use host window manager
  along with option --hostdisplay.
  You may get strange interferences with your host desktop.
  Can be interesting though, having two overlapping desktops."
    ;;

    --xorg)
      [ "$Hostsystem" = "opensuse" ] && [ "$Runsonconsole" = "no" ] && [ "$Startuser" != "root" ] && warning "openSUSE does not support starting a second Xorg server
  from within X. Possible solutions:
  1.) Install nested X server 'Xephyr', 'nxagent' or 'Xnest',
      or for --gpu support: install 'Weston' and 'Xwayland'.
  2.) Switch to console tty1...tty6 with <CTRL><ALT><F1>...<F6>
      and start x11docker there.
  3.) Run x11docker as root."

      case $Xlegacywrapper in
        yes) warning "Although x11docker starts Xorg as unprivileged user,
  most system setups wrap Xorg to give it root permissions (setuid).
  Evil containers may try to abuse this.
  Other x11docker X server options like --xephyr are more secure at this point." ;;
        no) [ "$Startuser" = "root" ] && warning "x11docker will run Xorg as root." ;;
      esac

      [ "$Runsoverssh" = "yes" ] && warning "x11docker can run Xorg on another tty (option --xorg),
  but you won't see it in your SSH session.
  Rather install e.g. Xephyr on ssh server and use option --xephyr."
    ;;

    --xpra|--xpra-xwayland)
      verlt "$Xpraversion" "v1.0" && {
        note "Your xpra version $Xpraversion is out of date. It is
  recommended to install at least xpra v1.0. Look at:  www.xpra.org"
        [ "$Desktopmode" = "yes" ] && {
          note "Your xpra version does not support desktop mode.
  Please use another X server option like --xephyr or --nxagent."
        } ||:
      }
      [ "$Desktopmode" = "yes" ] && verlt "$Xpraversion" "v2.2-r17117" && note "Xpra desktop mode works best since xpra v2.2-r17117.
  You have installed lower version xpra $Xpraversion.
  It is recommended to use --xephyr or --nxagent instead.
  Rendering issues can be reduced disabling OpenGL in Xpra tray icon. Screen
  size issues can be avoided with non-integer scaling (e.g. --scale=1.01)."
      [ "$Desktopmode" = "no" ] && verlt $Xprarelease r23066 && note "Xpra startup can be slow. For faster startup
  with seamless applications,   try --nxagent.
  If security is not a concern, try --hostdisplay.
  Xpra version v3.0-r23066 and higher starts up faster."
      [ "$Sharegpu" = "yes" ] && note "If performance of GPU acceleration with $Xserver
  is not satisfying, you can try insecure '--hostdisplay --gpu'."
      note "Option --xpra: If you encounter issues with xpra, 
  you can try --nxagent instead.
  Rather use xpra from www.xpra.org than from distribution repositories."
    ;;

  #  --xephyr) note "Xephyr is a quite stable nested X server.
  #Less stable, but directly resizeable is nxagent with option --nxagent.
  #Resizing of the Xephyr window is possible with xrandr, arandr or lxrandr."
  #  ;;

    --nxagent)
      [ "$Hostsystem" = "mageia" ] && {
        [ "$Desktopmode" = "no" ] && [ "$Autochooseserver" = "yes" ] && Desktopmode="yes" && Windowmanagermode="auto"
        [ "$Desktopmode" = "no" ] && warning "nxagent version 3.5.0 on Mageia 6 is known to crash
  in seamless mode. (Detected version: '$(strings --bytes 20 /usr/libexec/nx/nxagent | grep "NXAGENT - Version")').
  If you encounter issues, please try seamless --xpra (secure),
  --hostdisplay (insecure), or run --nxagent in desktop mode with a
  host window manager (--wm=WINDOWMANAGER or --wm=auto or short -wm)."
      }
      note "A few applications do not work well with --nxagent.
  In that case, you can try to fix the issue with option --composite
  or try another X server option like --xephyr or --xpra."
      [ "$Xcomposite" = "yes" ] && note "Option --nxagent: nxagent can have issues with option
  --composite. Maybe rather try --xephyr or --xpra."
    ;;

    --weston|--kwin|--hostwayland)
      note "You are running a pure Wayland environment.
  X applications without Wayland support will fail."
      [ "$Xserver" = "--kwin" ] && note "kwin_wayland (option --kwin) does not support the xdg_shell
  interface in all versions. Some GTK3 Wayland applications depend on it.
  If application startup fails, try --weston instead."
    ;;
  esac
  
  # NVIDIA without --gpu
  [ "$Nvidiaversion" ] && [ "$Sharegpu" = "no" ] && case $Xserver in
    --hostdisplay|--xorg) note "Option $Xserver may fail with proprietary NVIDIA driver
  on host. In that case try other X server options like 
  --nxagent, --xpra or --xephyr." ;;
  esac
  
  # --iglx
  [ "$Iglx" = "yes" ] && [ -z "$Nvidiaversion" ] && note "Option --iglx: iGLX is known to have a bug in libgl
  of free MESA drivers. You might get black content only."

  # --fullscreen
  [ "$Fullscreen" = "yes" ] && {
    case $Xserver in
      --xephyr|--weston|--weston-xwayland|--nxagent|--xpra|--xpra-xwayland|--xwin) ;;
      --xdummy|--xdummy-xwayland|--xvfb|--xorg) ;;
      *) note "$Xserver does not support option --fullscreen" ;;
    esac
  }

  # --output-count
  [ "$Outputcount" != "1" ] && {
    case $Xserver in
      --weston-xwayland) note "Xwayland sometimes does not position itself well
  at origin 0+0 of first virtual screen, and some screens appear to be unused.
  You may need to move Xwayland manually with [META]+[LeftMouseButton].
  (Bug report at https://bugzilla.redhat.com/show_bug.cgi?id=1498665 )" ;;
      --xephyr) note "Xinerama support would be best for multiple outputs,
  but is disabled in Xephyr because Xephyr does not handle it well.
  Different window managers handle this different. Just try out." ;;
    esac
  }
  
  # --webcam
  [ "$Sharewebcam" = "yes" ] && warning "Option --webcam: Container applications might look 
  at you and also might take screenshots of your Desktop."
  
  # --hostipc
  [ "$Sharehostipc" = "yes" ] && warning "Option --hostipc severely degrades 
  container isolation. IPC namespace remapping is disabled."
  
  # --init
  case $Initsystem in
    systemd)
      grep -q cgroup2 /proc/filesystems && note "Option --init=systemd: Found cgroup v2
  on your system. systemd in container might fail without an error message.
  As a workaround you can set a kernel boot option to enforce cgroup v1:
    systemd.unified_cgroup_hierarchy=0
  Compare ticket https://github.com/mviereck/x11docker/issues/349"
    ;;
  esac

  # --network
  [ "$Network" = "host" ] && warning "Option --network=host severely degrades 
  container isolation. Network namespacing is disabled. 
  Container shares host network stack. 
  Spying on network traffic may be possible. 
  Access to host X server $Hostdisplay may be possible 
  through abstract unix socket."
  
  # --sudouser
  [ "$Sudouser" ] && [ "$Containeruseruid" != "0" ] && [ "$Network" != "host" ] && [ -z "$Xoverip" ] && note "Option --sudouser: If you want to run GUI application
  with su or sudo, you might need to add either option --xoverip 
  or (discouraged) option --network=host."
  
  # --user=RETAIN / keep container defined in image
  case $Createcontaineruser in
    no)
      [ "$Sudouser" ] && note "Option --sudouser has limited support with --user=RETAIN.
  x11docker will only set needed capabilities. 
  User setup and /etc/sudoers won't be touched.
  Option --group-add=sudo might be useful."
    ;;
  esac
  
  [ "$Customdockeroptions" ] && {
    warning "Found custom DOCKER_RUN_OPTIONS.
  x11docker will add them to 'docker run' command without
  a serious check for validity or security. Found options:
  $Customdockeroptions"
    grep -q -- '--privileged'           <<< "$Customdockeroptions" && warning "Found option --privileged
  in custom docker run options. That is A VERY BAD IDEA.
  A privileged setup allows unrestricted access from container to host.
  Malicious applications can cause arbitrary harm."
    grep -q -i -- '--cap-add.ALL'       <<< "$Customdockeroptions" && warning "Found option --cap-add=ALL
  in custom docker run options. That is A VERY BAD IDEA.
  That is a very privileged setup.
  Malicious applications may harm to the host."
    grep -q -i -- '--cap-add.SYS_ADMIN' <<< "$Customdockeroptions" && warning "Found option --cap-add=SYS_ADMIN
  in custom docker run options. That is A VERY BAD IDEA.
  That is a very privileged setup.
  Malicious applications may harm to the host."
    grep -q -- '--entrypoint'           <<< "$Customdockeroptions" && warning "Found option --entrypoint
  in custom docker run options. x11docker uses this option, too.
  This setup will probably fail. Use x11docker option --no-entrypoint instead
  and add desired command as container command after the image name."
    grep -q -- "--user"                 <<< "$Customdockeroptions" && warning "Found option --user in custom DOCKER_RUN_OPTIONS.
  This might lead to errors or unexpected behaviour.
  Please use x11docker option --user instead."
    grep -q -- "--runtime"              <<< "$Customdockeroptions" && note "Found option --runtime in custom DOCKER_RUN_OPTIONS.
  Please use x11docker option --runtime instead."
    grep -q -- "--network"              <<< "$Customdockeroptions" && note "Found option --network in custom DOCKER_RUN_OPTIONS.
  Please use x11docker option --network instead."
    grep -q -- "--name"                 <<< "$Customdockeroptions" && note "Found option --name in custom DOCKER_RUN_OPTIONS.
  Please use x11docker option --name instead."
    grep -q -- "--group-add"            <<< "$Customdockeroptions" && note "Found option --group-add in custom DOCKER_RUN_OPTIONS.
  Please use x11docker option --group-add instead."
  }
  
  return 0
}