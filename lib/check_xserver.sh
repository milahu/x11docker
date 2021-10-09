check_xserver() {               # check chosen X server, auto-choose X server

  ## default option '--auto': Try to automatically choose best matching and available X server
  [ "$Autochooseserver" = "yes" ] && {                              Xserver="--xpra"
    [ "$Sharegpu" = "yes" ]                                      && Xserver="--xpra-xwayland"
    [ "$Xfishtank" = "yes" ]                                     && Xserver="--xephyr"
    [ "$Desktopmode" = "yes"  ]                                  && Xserver="--xephyr"
    [ "$Xserver" = "--xephyr" ] && { check_xdepends --xephyr     || Xserver="--weston-xwayland" ; }  ### FIXME: don't use check_xdepends() here
    [ "$Sharegpu" = "yes" ]     && [ "$Xserver" = "--xephyr" ]   && Xserver="--weston-xwayland"
    [ "$Outputcount" != "1" ]                                    && Xserver="--weston-xwayland"
    [ -n "$Rotation" ]                                           && Xserver="--weston-xwayland"
    [ "$Scaling" ]              && [ "$Sharegpu" = "yes" ]       && Xserver="--xpra-xwayland"
    [ "$Scaling" ]              && [ "$Sharegpu" = "no" ]        && Xserver="--xpra"
    [ "$Runsonconsole" = "yes" ]                                 && Xserver="--xorg"
    [ -z "$Hostdisplay" ]       && [ -n "$Hostwaylandsocket" ]   && Xserver="--xpra"
    [ "$Winsubsystem" ]                                          && Xserver="--runx"
    [ "$Winsubsystem" = "CYGWIN" ]                               && Xserver="--xwin"
    [ "$Setupwayland" = "yes" ] && { [ -n "$Hostwaylandsocket" ] && [ "$Desktopmode" = "no" ] && Xserver="--hostwayland" || Xserver="--weston" ; }
  }

  [ "$Sharegpu" = "yes" ] && {
    case $Xserver in
      --xpra)
        note "Option --xpra does not support GPU access.
  Fallback: Will try to use option --xpra-xwayland."
        check_fallback
        Xserver="--xpra-xwayland"
      ;;
      --xephyr)
        note "Option --xephyr does not support GPU access.
  Fallback: Will try to use option --weston-xwayland."
        check_fallback
        Xserver="--weston-xwayland"
      ;;
      --nxagent)
        case "$Desktopmode" in
          yes) Xserver="--weston-xwayland" ;;
          no)  Xserver="--xpra-xwayland" ;;
        esac
        note "Option --nxagent does not support GPU access.
  Fallback: Will try to use option $Xserver."
        check_fallback
      ;;
      --xdummy|--xvfb)
        note "Using special setup with Weston, Xwayland and xdotool
  instead of Xdummy or Xvfb to allow GPU access."
        Xserver="--xdummy-xwayland"
      ;;
    esac
  }
  
  grep -q -i "GNOME" <<< "$XDG_CURRENT_DESKTOP" && {
    Gnomeversion="$(gnome-shell --version)"
    [ "$Gnomeversion" ] && verlt "$Gnomeversion" "GNOME Shell 3.38" && {
      case $Xserver in
        --hostdisplay|--xorg|--tty) ;;
        *)
          warning "You are running GNOME desktop in outdated version 
  $Gnomeversion
  This might cause issues with host applications if using additional X servers.
  It is recommended to use another desktop environment or GNOME >= 3.38.
  Only --xorg or discouraged option --hostdisplay might work as expected."
          [ "$Autochooseserver" = "yes" ] && case "$Desktopmode" in
            "yes") Xserver="--xorg" ;;
            "no")  Xserver="--hostdisplay" ;;
          esac
        ;;
      esac
    }
  }

  # X over TCP
  [ -z "$Xoverip" ] && {
    [ "$Runtime" = "kata-runtime" ] && Xoverip="yes"
    case $Mobyvm in
      yes)                             Xoverip="yes" ;;
    esac
    [ "$Xoverip" = "yes" ] && [ "$Autochooseserver" = "no" ] && debugnote "Enabled X over TCP instead of sharing unix socket."
  }

  [ "$Nvidiaversion" ] && [ "$Sharegpu" = "yes" ] && case $Xserver in
    --xpra-xwayland|--weston-xwayland|--xwayland|--weston|--kwin|--kwin-xwayland|--xdummy-xwayland|--hostwayland)
      note "Your system uses closed source NVIDIA driver.
  GPU support will work only with options --hostdisplay and --xorg.
  Consider to use free open source nouveau driver instead."
    ;;
  esac
  
  [ "$Runsonconsole" = "no" ] && [ "$Runsoverssh" = "no" ] && [ -z "$Hostdisplay$Hostwaylandsocket" ] && [ "$Xserver" != "--tty" ] && [ -z "$Winsubsystem" ] && {
    warning "Environment variables DISPLAY and WAYLAND_DISPLAY are empty,
  but it seems x11docker was started within X, not from console.
  Please set DISPLAY and XAUTHORITY.
  If you have started x11docker with su or sudo, su/sudo may be configured to
  unset X environment variables. It may work if you run x11docker with
    sudo -E x11docker [...]
  If your system does not support 'sudo -E', you can try
    sudo env DISPLAY=\$DISPLAY XAUTHORITY=\$XAUTHORITY x11docker [...]
  Otherwise, you can use tools like gksu/gksudo/kdesu/kdesudo/lxsu/lxsudo."

    [ -n "${PKEXEC_UID:-}" ] && note "It seems you have started x11docker with pkexec.
  Can not determine DISPLAY and XAUTHORITY, can not use your X server.
  To allow other X server options, please provide environment variables with
    pkexec env DISPLAY=\$DISPLAY XAUTHORITY=\$XAUTHORITY x11docker [ARGS]."

    [ "$Autochooseserver" = "yes" ] && Xserver="--xorg"
  }

  [ "$Runsoverssh" = "yes" ] && [ -z "$Hostdisplay$Hostwaylandsocket" ] && [ "$Xserver" != "--tty" ] && [ "$Autochooseserver" = "yes" ] && {
    error "You are running x11docker over SSH without providing a display.
  Please run with 'ssh -X' or 'ssh -Y'.
  (If you insist, you can run with option '--xorg', but won't see the result remotely.)"
  }
  
  ## check if dependencies for chosen X server are installed, fall back to best alternatives if not
  [ "$Xserver" = "--xwin" ]            && { check_xdepends --xwin            || Xserver="--runx" ; }
  [ "$Xserver" = "--runx" ]            && { check_xdepends --runx            || Xserver="--hostdisplay" ; }
  [ "$Xserver" = "--hostdisplay" ]     && { check_xdepends --hostdisplay     || Xserver="--xpra" ; }
  [ "$Xserver" = "--xephyr" ]          && { check_xdepends --xephyr          || Xserver="--nxagent" ; }
  [ "$Xserver" = "--xvfb" ]            && { check_xdepends --xvfb            || Xserver="--xdummy"  ; }
  [ "$Xserver" = "--hostwayland" ]     && { check_xdepends --hostwayland     || Xserver="--weston"  ; }
  [ "$Xserver" = "--nxagent" ]         && { check_xdepends --nxagent         || { [ "$Desktopmode" = "yes" ] && Xserver="--xephyr"        || Xserver="--xpra" ; } ; }
  [ "$Xserver" = "--xpra" ]            && { check_xdepends --xpra            || { [ -z "$Hostdisplay" ]      && Xserver="--weston-xwayland" ; } ; }
  [ "$Xserver" = "--xpra" ]            && { check_xdepends --xpra            || { check_xdepends --nxagent   && Xserver="--nxagent"       || Xserver="--xephyr" ; } ; }
  [ "$Xserver" = "--xorg" ]            && { check_xdepends --xorg            || Xserver="--weston-xwayland" ; }
  [ "$Xserver" = "--xpra-xwayland" ]   && { check_xdepends --xpra-xwayland   || Xserver="--weston-xwayland" ; }
  [ "$Xserver" = "--xwayland" ]        && { check_xdepends --xwayland        || Xserver="--weston-xwayland" ; }
  [ "$Xserver" = "--xpra-xwayland" ]   && { check_xdepends --xpra-xwayland   || { [ "$Desktopmode" = "yes" ] && Xserver="--kwin-xwayland" || Xserver="--hostdisplay" ; } ; }
  [ "$Xserver" = "--kwin-xwayland" ]   && { check_xdepends --kwin-xwayland   || Xserver="--weston-xwayland" ; }
  [ "$Xserver" = "--kwin" ]            && { check_xdepends --kwin            || Xserver="--weston" ; }
  [ "$Xserver" = "--weston-xwayland" ] && { check_xdepends --weston-xwayland || Xserver="--kwin-xwayland" ; }
  [ "$Xserver" = "--weston" ]          && { check_xdepends --weston          || Xserver="--kwin" ; }
  [ "$Xserver" = "--xdummy-xwayland" ] && { check_xdepends --xdummy-xwayland || Xserver="--kwin-xwayland" ; }

  case $Xserver in
    --weston|--kwin|--hostwayland) Setupwayland="yes" ;;
  esac
  [ "$Setupwayland" = "yes" ]          && { check_xdepends $Xserver || error "Failed to set up a Wayland environment.
  Please install 'weston' or 'kwin_wayland'.
  Wayland is not possible with proprietary NVIDIA driver
  or with --runtime=kata-runtime." ; }

   # Xephyr as fallback for all options. Last fallback: Xorg
  check_xdepends $Xserver || Xserver="--xephyr"
  [ "$Xserver" = "--xephyr" ]         && {  check_xdepends --xephyr || {
                                              check_xdepends --kwin-xwayland   && Xserver="--kwin-xwayland"
                                              check_xdepends --hostdisplay     && [ "$Desktopmode" = "no" ] && Xserver="--hostdisplay"
                                              check_xdepends --runx            && Xserver="--runx"
                                              check_xdepends --xwin            && Xserver="--xwin"
                                              check_xdepends --nxagent         && Xserver="--nxagent"
                                              check_xdepends --weston-xwayland && Xserver="--weston-xwayland"
                                              check_xdepends --xpra            && Xserver="--xpra"
                                            }
    [ "$Sharegpu" = "yes" ] && case $Desktopmode in
      yes)                                  check_xdepends --weston-xwayland && Xserver="--weston-xwayland" ;;
      no)                                   check_xdepends --hostdisplay     && Xserver="--hostdisplay" ;;
    esac
    [ "$Runsonconsole" = "yes" ] && {
                                            check_xdepends --kwin-xwayland   && Xserver="--kwin-xwayland"
                                            check_xdepends --weston-xwayland && Xserver="--weston-xwayland"
                                            check_xdepends --xorg            && Xserver="--xorg"
    }
    check_xdepends $Xserver || Xserver="--xorg"
  }
  
  check_xdepends $Xserver || {
    case $Winsubsystem in
      "") 
        error "Did not find a possibility to provide a display.
  Recommendations:
    To run within an already running X server, 
    install 'xinit' and one or all of:
      Xephyr xpra nxagent
    To run with GPU acceleration, install:
      weston and Xwayland, optionally also: xpra and xdotool
    To run from TTY or within Wayland, install:
      weston and Xwayland
  $Wikipackages" 
      ;;
      CYGWIN) 
        error "Did not find a possibility to provide a display.
  Please install packages 'xinit' and 'xauth' in Cygwin,
  or run x11docker with --runx:  https://github.com/mviereck/runx" 
      ;;
      MSYS2|WSL1|WSL2) 
        [ "$Hostdisplay" ] && {
          error "Did not find a possibility to provide a nested display.
  Please install package 'xinit' and one or all of:  nxagent Xephyr xpra
  $Wikipackages"
        } || {
        error "Did not find a possibility to provide a display.
  Please use --runx to provide an X server on MS Windows: 
    https://github.com/mviereck/runx" 
        }
      ;;
    esac
  }

  [ "$Autochooseserver" = "yes" ] && note "Using X server option $Xserver" 
  storeinfo "xserver=$Xserver"
  return 0
}