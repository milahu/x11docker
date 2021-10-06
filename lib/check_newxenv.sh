check_newxenv() {               # find free display, create $Newxenv
  local Line
  # find free display number
  [ "$Newdisplaynumber" ] || {
    Newdisplaynumber="100"
    while :; do
      case $Xserver in
        --xwin|--runx) Newdisplaynumber="$((RANDOM / 10 + 200))" ;;
        *)             Newdisplaynumber="$((Newdisplaynumber + 1))" ;;
      esac
      grep -q -x "$Newdisplaynumber" < "$Numbersinusefile" || [ -n "$(find "/tmp/.X11-unix/X$Newdisplaynumber" "/tmp/.X$Newdisplaynumber-lock" "$XDG_RUNTIME_DIR/wayland-$Newdisplaynumber" 2>/dev/null)" ] || break
    done
  }
  echo "$Newdisplaynumber" >> "$Numbersinusefile"

  # X over IP/TCP
  [ "$Xoverip" ] || case $Xserver in
    --xwin|--runx) Xoverip="yes" ;;
  esac
  
  # set $Newdisplay (DISPLAY of container) and $Newxsocket
  case $Xserver in
    --hostdisplay)
      case $Xoverip in
        yes) 
          [ "$(cut -c1 <<< "$Hostdisplay")" = ":" ] && Newdisplay="${Hostip}${Hostdisplay}" || Newdisplay="$Hostdisplay"  ;;
        no|"")
          Newdisplay="$Hostdisplay"
          Newdisplaynumber="$(echo $Newdisplay | cut -d: -f2 | cut -d. -f1)"
          Newxsocket="$Hostxsocket"
        ;;
      esac
    ;;
    --weston|--kwin|--hostwayland|--tty)
      Newdisplay=""
      Newxsocket=""
      Xclientcookie=""
      Xservercookie=""
    ;;
    *)
      case $Xoverip in
        yes) Newdisplay="$Hostip:$Newdisplaynumber" ;;
        no|"")
          Newdisplay=":$Newdisplaynumber"
          Newxsocket="/tmp/.X11-unix/X$Newdisplaynumber"
          Newxlock="/tmp/.X$Newdisplaynumber-lock"
          [ -n "$(find $Newxsocket $Newxlock 2>/dev/null)" ] && error "Display $Newdisplay is already in use."
        ;;
      esac
    ;;
  esac

  # set $Newwaylandsocket
  case $Xserver in
    --weston|--weston-xwayland|--kwin|--kwin-xwayland|--xpra-xwayland|--xdummy-xwayland) Newwaylandsocket="wayland-$Newdisplaynumber" ;;
    --hostwayland|--xwayland)                                                            Newwaylandsocket="$Hostwaylandsocket" ;;
  esac


  # create $Newxenv: collection of environment variables to access new X from host (e.g. in xinitrc)
  [ "$Newdisplay" ]         && storeinfo "DISPLAY=$Newdisplay"                && Newxenv="$Newxenv DISPLAY=$Newdisplay"
  [ -e "$Xclientcookie" ]   && storeinfo "XAUTHORITY=$Xclientcookie"          && Newxenv="$Newxenv XAUTHORITY=$Xclientcookie"
  [ "$Newxsocket" ]         && storeinfo "XSOCKET=$Newxsocket"                && Newxenv="$Newxenv XSOCKET=$Newxsocket"
  [ "$Newwaylandsocket" ]   && storeinfo "WAYLAND_DISPLAY=$Newwaylandsocket"  && Newxenv="$Newxenv WAYLAND_DISPLAY=$Newwaylandsocket"
  [ "$Setupwayland" = "yes" ] && for Line in $Waylandtoolkitenv ; do             Newxenv="$Newxenv $Line" ; done
  [ -n "$XDG_RUNTIME_DIR" ] && storeinfo "XDG_RUNTIME_DIR=$XDG_RUNTIME_DIR"   && Newxenv="$Newxenv XDG_RUNTIME_DIR=$XDG_RUNTIME_DIR"
  storeinfo "Xenv=$Newxenv"
  
  # X / Wayland environment variables for container
  case $Xserver in
    --xpra|--xephyr|--xpra-xwayland|--weston-xwayland|--hostdisplay|--xorg|--xdummy|--xvfb|--xdummy-xwayland|--xwayland|--kwin-xwayland|--nxagent|--xwin|--runx)
      store_runoption env "DISPLAY=$Newdisplay"
      store_runoption env "XAUTHORITY=$(convertpath share $Xclientcookie)"
    ;;
    --weston|--kwin|--hostwayland|--tty)
      store_runoption env "WAYLAND_DISPLAY=$Newwaylandsocket"
    ;;
  esac
  return 0
}