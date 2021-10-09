check_terminalemulator() {      # check terminal for password prompt of su or sudo
  # $Passwordterminal:  To prompt for su or sudo password

  # Not working: pangoterm lilyterm fbterm
  # Makes problems if X and Wayland are independently available at same time: xfce4-terminal
  # Works, but does not appear: 'guake -te'
  
  local Terminallist

  Terminallist="xterm mintty lxterm lxterminal stterm sakura termit pterm terminator terminology Eterm konsole qterminal gnome-terminal mate-terminal mrxvt rxvt xvt kterm mlterm xfce4-terminal bash"
  [ -z "$Hostdisplay" ] && [ -n "$Hostwaylandsocket" ] && Terminallist="konsole qterminal gnome-terminal bash"
  [ "$Runsinterminal" = "yes" ] && Terminallist="bash"

  for Passwordterminal in $Terminallist ; do command -v $Passwordterminal >/dev/null && break ; done

  [ -z "$Hostdisplay" ] && [ -n "$Hostwaylandsocket" ] && {
    case $Passwordterminal in
      qterminal) Passwordterminal="env QT_QPA_PLATFORM=wayland $Passwordterminal -e" ;;
      konsole) Passwordterminal="env QT_QPA_PLATFORM=wayland dbus-run-session $Passwordterminal --nofork -e" ;;
    esac
  }
  [ -z "$Hostdisplay$Hostwaylandsocket" ] && Passwordterminal="bash"
  
  case $Passwordterminal in
    xfce4-terminal) Passwordterminal="$Passwordterminal --disable-server -x" ;;
    mate-terminal)  Passwordterminal="dbus-run-session $Passwordterminal -x" ;;
    gnome-terminal) Passwordterminal="dbus-launch $Passwordterminal --" ;;
    terminator)     Passwordterminal="dbus-run-session $Passwordterminal --no-dbus -x" ;;
    konsole)        Passwordterminal="dbus-run-session $Passwordterminal --nofork -e" ;;
    bash)           Passwordterminal="eval" ;;
    *)              Passwordterminal="$Passwordterminal -e" ;;
  esac

  return 0
}