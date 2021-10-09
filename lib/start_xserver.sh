start_xserver() {               # start X server
  case $Xserver in
    --xpra|--xephyr|--xdummy|--xvfb|--xwayland|--nxagent|--weston-xwayland|--kwin-xwayland|--xpra-xwayland|--xdummy-xwayland|--xwin)
      unpriv "env WAYLAND_DISPLAY=$Newwaylandsocket      xinit $Xinitrc -- $Xcommand             >> $Xinitlogfile  2>&1 " ;;
    --xorg)
      case $Xlegacywrapper in
        yes) unpriv  "                                   xinit $Xinitrc -- $Xcommand             >> $Xinitlogfile  2>&1 " ;;
        no)  eval    "                                   xinit $Xinitrc -- $Xcommand             >> $Xinitlogfile  2>&1 " ;;
      esac
    ;;
    --hostdisplay|--hostwayland|--weston|--kwin|--tty)
      unpriv "                                           bash  $Xinitrc                          >> $Xinitlogfile  2>&1 " ;;
    --runx) unpriv "                        $Xcommand -- bash  $Xinitrc                          >> $Xinitlogfile  2>&1 " ;;
  esac

  [ $? != 0 ] && rocknroll && note "X server $Xserver returned an error code.
  Last lines of xinit logfile:
$(tail $Xinitlogfile)

  $( [ -s "$Compositorlogfile" ] && echo "Last lines of compositor log:
$(tail $Compositorlogfile)")"
  return 0
}