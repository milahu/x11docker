start_compositor() {            # start Wayland compositor Weston or KWin
  local Compositorkeyword
  
  case $Xserver in
    --weston|--weston-xwayland|--xpra-xwayland|--xdummy-xwayland) Compositorkeyword="weston-desktop-shell" ;;
    --kwin|--kwin-xwayland)                                       Compositorkeyword="X-Server" ;;
  esac
  
  unpriv "$(command -v dbus-launch) $Compositorcommand  >> $Compositorlogfile  2>&1 & echo compositorpid=\$! >>$Storeinfofile"
  storeinfo "compositorpid=$(storeinfo dump compositorpid)"
  waitforlogentry "start_compositor()" "$Compositorlogfile" "$Compositorkeyword" "$Compositorerrorcodes"
  setonwatchpidlist "$(storeinfo dump compositorpid)" compositor

  case $Xserver in
    --xpra-xwayland|--xdummy-xwayland)  # hide weston window
      unpriv "xdotool windowunmap 0x$(printf '%x\n' $(grep 'window id' $Compositorlogfile | rev | cut -d' ' -f1 | rev))" ;;
  esac
  return 0
}