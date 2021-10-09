check_vt() {                    # option --xorg: find free vt / tty
  local Line= Ttyinuse=
  
  # if started from console, use current tty
  tty -s && [ "$Runsonconsole" = "yes" ] && {
    Newxvt="$(tty | rev | cut -d/ -f1 | rev)"
    Newxvt="${Newxvt#tty}"
  }

  # check ttys currently in use
  [ "$Newxvt" ] || {
    for Line in $(find /sys/class/vc/vcsa*); do
      Ttyinuse="$Ttyinuse ${Line#/sys/class/vc/vcsa} "
    done
    debugnote "check_vt(): TTYs currently known to kernel: $Ttyinuse"
  }

  [ "$Newxvt" ] && grep -q " $Newxvt " <<< "$Ttyinuse" && warning "TTY $Newxvt seems to be already in use."

  # try to find free tty within range of 8..12
  [ "$Newxvt" ] || {
    for ((Newxvt=8 ; Newxvt<=12 ; Newxvt++)) ; do
      grep -q " $Newxvt " <<< "$Ttyinuse" || break
    done
  }

  # try to find free tty within range of 1..7
  [ "$Newxvt" ] || {
    for ((Newxvt=1 ; Newxvt<=7 ; Newxvt++)) ; do
      grep -q " $Newxvt " <<< "$Ttyinuse" || break
    done
  }

  # try to find free tty with fgconsole. Fails in some cases within X.
  [ "$Newxvt" ] || Newxvt="$(fgconsole --next-available 2>/dev/null)"
  [ "$Newxvt" ] || Newxvt="$(fgconsole --next-available 2>/dev/null </dev/tty${XDG_VTNR:-})"

  # try to find free tty within range of 13..63
  [ "$Newxvt" ] || {
    for ((Newxvt=13 ; Newxvt<=63 ; Newxvt++)) ; do
      grep -q " $Newxvt " <<< "$Ttyinuse" || break
    done
  }

  [ "$Newxvt" ] || error "Could not identify a free tty for --xorg."

  [ "${XDG_VTNR:-}" ] && [ "$Hostdisplay$Hostwaylandsocket" ] && note "Current X server $Hostdisplay runs on tty ${XDG_VTNR:-}.
  Access it with [CTRL][ALT][F${XDG_VTNR:-}]."

  [ "${Newxvt:-999}" -gt "12" ] && {
    fgconsole --next-available 1>/dev/null 2>/dev/null || note "Could not check for a free tty below or equal to 12.
  Would need to use command fgconsole for a better check.
  Possibilities:
  1.) Run x11docker as root.
  2.) Add user to group tty (not recommended, may be insecure).
  3.) Use display manager gdm3.
  4.) Run x11docker directly from console."
    note "To access X on tty$Newxvt, use command 'chvt $Newxvt'"
  } || {
    note "New Xorg server $Newdisplay will run on tty $Newxvt.
  Access it with [CTRL][ALT][F$Newxvt]."
  }

  warning "On debian 9, switching often between multiple X servers can
  cause a crash of one X server. This bug may be debian specific and is probably
  some sort of race condition. If you know more about this or it occurs on
  other systems, too, please report at https://github.com/mviereck/x11docker.

  You can avoid this issue with switching to a black tty before switching to X."
  return 0
}