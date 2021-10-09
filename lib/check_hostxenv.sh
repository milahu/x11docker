check_hostxenv() {              # check environment variables for host X display
  Hostdisplay="${DISPLAY:-}"
  Hostdisplaynumber="$(echo $Hostdisplay | cut -d: -f2 | cut -d. -f1)"                         # display number without ":" and ".0"
  [ -n "$Hostdisplay" ] && Hostxsocket="/tmp/.X11-unix/X$Hostdisplaynumber" || Hostxsocket=""  # X socket from host, needed for --hostdisplay
  [ -e "$Hostxsocket" ] || Hostxsocket=""                                                      # can miss in SSH session
  
  # Check whether host X server has MIT-SHM enabled.
  command -v xdpyinfo >/dev/null && xdpyinfo >/dev/null 2>&1 && {
    xdpyinfo | grep -q "MIT-SHM" && Hostmitshm="yes" || Hostmitshm="no"
  }
  [ "$Winsubsystem" ] && Hostmitshm="no"
  
  # get cookie from host display
  XAUTHORITY=${XAUTHORITY:-}
  [ -z "$XAUTHORITY" ]   && command -v systemctl >/dev/null    && XAUTHORITY="$(systemctl --user show-environment | grep XAUTHORITY= | cut -d= -f2)"
  [ -z "$XAUTHORITY" ]   && [ -e "$Hostuserhome/.Xauthority" ] && XAUTHORITY="$Hostuserhome/.Xauthority"
  [ -z "$XAUTHORITY" ]   && [ "$Runsoverssh" = "yes" ] && [ -e "$Hostuserhome/.Xauthority" ] && XAUTHORITY="$Hostuserhome/.Xauthority"
  [ "${XAUTHORITY:-}" ]  && {
    unpriv "xauth -i -f ${XAUTHORITY:-} nlist $Hostdisplay 2>/dev/null | xauth -f $Hostxauthority nmerge - 2>/dev/null"
    chown $Hostuser $Hostxauthority
    chmod 600 $Hostxauthority
    export XAUTHORITY
  } || {
    Hostxauthority=""
    unset XAUTHORITY
  }
  [ "$Hostdisplay" ] || {
    Hostxsocket=""
    Hostxauthority=""
    XAUTHORITY=""
  }
  [ -s "${XAUTHORITY:-}" ] && [ ! -s "$Hostxauthority" ] && cp "${XAUTHORITY:-}" "$Hostxauthority"

  # create $Hostxenv
  Hostxenv="DISPLAY=$Hostdisplay"
  [ -s "$Hostxauthority" ] && {
    Hostxenv="$Hostxenv XAUTHORITY=$Hostxauthority"
    export XAUTHORITY=$Hostxauthority
  } || {
    Hostxauthority=
    unset XAUTHORITY
  }
  [ -n "$Hostxsocket" ]       && Hostxenv="$Hostxenv XSOCKET=$Hostxsocket"
  [ -n "$Hostwaylandsocket" ] && Hostxenv="$Hostxenv WAYLAND_DISPLAY=$Hostwaylandsocket"
  Hostxenv="$Hostxenv XDG_RUNTIME_DIR=$XDG_RUNTIME_DIR"
  [ -n "$Hostdisplay" ] && [ -z "$Hostxauthority" ] && warning "Your host X server runs without cookie authentication."
  
  [ -z "$GDK_BACKEND" ] && {
    [ -n "$Hostwaylandsocket" ] && export GDK_BACKEND="wayland"
    [ -n "$Hostdisplay" ]       && export GDK_BACKEND="x11"
    [ -z "$Hostdisplay$Hostwaylandsocket" ] && unset GDK_BACKEND
  }

  return 0
}