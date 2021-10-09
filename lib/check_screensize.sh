check_screensize() {            # check physical and virtual screen size (also option --size)
  local Line=
  
  [ -z "$Hostdisplay" ] && [ -n "$Hostwaylandsocket" ] && verbose "check_screensize(): Skipping check on pure Wayland environment"

  # check whole display size, can include multiple monitors
  [ -n "$Hostdisplay" ] && {
    command -v xrandr >/dev/null && {
      Line="$(xrandr 2>/dev/null | grep current | head -n1 | cut -d, -f2)"
      Maxxaxis="$(echo "$Line" | cut -d' ' -f3)"
      Maxyaxis="$(echo "$Line" | cut -d' ' -f5)"
    }
    [ -z "$Maxxaxis" ] && command -v xdpyinfo >/dev/null && {
      Line="$(xdpyinfo | grep dimensions)"
      Maxxaxis="$(echo "$Line" | cut -dx -f1 | rev | cut -d ' ' -f1 | rev)"
      Maxyaxis="$(echo "$Line" | cut -dx -f2 | cut -d ' ' -f1)"
    }
    [ -z "$Maxxaxis" ] && command -v xwininfo >/dev/null && {
      Line="$(xwininfo -root -stats)"
      Maxxaxis="$(echo "$Line" | grep Width  | rev | cut -d' ' -f1 | rev)"
      Maxyaxis="$(echo "$Line" | grep Height | rev | cut -d' ' -f1 | rev)"
    }
    [ -z "$Maxxaxis" ] && note "check_screensize(): Could not determine your screen size.
  Please improve this by installing one of xrandr, xdpyinfo or xwininfo.
  Or use option --size=XxY.
  $Wikipackages"
  }
  
  case $Xserver in
    --xvfb|--xdummy)
      [ "$Screensize" ] && {
        Maxxaxis="${Screensize%x*}"
        Maxyaxis="${Screensize#*x}"
      } || {
        Maxxaxis=4720
        Maxyaxis=3840
        note "Option $Xserver: Specifying quite big virtual screen size
  for $Xserver: ${Maxxaxis}x${Maxyaxis}
  This costs some memory, but will fit most possible remote screens.
  To save memory, specify needed screen size only with e.g. --size=1980x1200
  Check output of 'xrandr | grep current' on your target display."
      }
    ;;
  esac

  [ -n "$Maxxaxis" ] && {
    Xaxis="$Maxxaxis"
    Yaxis="$Maxyaxis"
  }

  [ "$Fullscreen" = "yes" ] && [ "$Runsonconsole" = "no" ] && [ -n "$Maxxaxis" ] && Screensize="${Maxxaxis}x${Maxyaxis}"

  # size for windowed desktops, roughly maximized relative to primary monitor
  case $Xserver in
    --xpra|--xpra-xwayland) [ "$Desktopmode" = "yes" ] && Xserver="${Xserver}-desktop" ;;
  esac
  case $Xserver in
    --xephyr|--weston-xwayland|--weston|--kwin|--kwin-xwayland|--nxagent|--xpra-desktop|--xpra-xwayland-desktop)
      [ "$Runsonconsole" = "yes" ] && {
        : # nothing to do on tty. ### FIXME maybe should check --size=$Screensize
      } || {
        command -v xrandr > /dev/null && xrandr 2>/dev/null | grep -q ' connected' && { # reduce size to primary monitor for windowed desktop
          Xaxis="$(xrandr 2>/dev/null | grep ' connected' | head -n1 | cut -dx -f1 | rev | cut -d' ' -f1 | rev)"
          Yaxis="$(xrandr 2>/dev/null | grep ' connected' | head -n1 | cut -dx -f2 | cut -d' ' -f1 | cut -d+ -f1)"
          Xaxis="$((Xaxis-96))"
          Yaxis="$((Yaxis-96))"
          Xaxis="$(( $(( $Xaxis / 8 )) * 8 ))"  # avoid grey edge in Xwayland, needs full byte x width
        } || {
          note "Could not determine size of your primary display to
  create a roughly maximized window for $Xserver.
  Please install xrandr or use option --size=XxY.
  Fallback: setting virtual screen size 800x600
  $Wikipackages"
          Xaxis="800"
          Yaxis="600"
        }
      }
    ;;
  esac
  Xserver="${Xserver%-desktop}"

  [ -z "$Xaxis" ] && {       ### FIXME: arbitrary resolution. At least, --xorg checks again with xrandr in xinitrc
    Xaxis="4720"
    Yaxis="3840"
  }

  # regard scaling (option --scale)
  [ "$Scaling" ] && {
    Xaxis="$(awk -v a=$Xaxis -v b=$Scaling 'BEGIN {print (a / b)}')"
    Xaxis="${Xaxis%.*}"
    Yaxis="$(awk -v a=$Yaxis -v b=$Scaling 'BEGIN {print (a / b)}')"
    Yaxis="${Yaxis%.*}"
  }
  [ -n "$Screensize" ] && {  # regard --size, overwriting Xaxis/Yaxis from above
    Xaxis="${Screensize%x*}"
    Yaxis="${Screensize#*x}"
  }
  case $Xserver in
    --xorg) ;;  # Xorg autodetects screen size, preset only with option --size
    *) [ "$Runsonconsole" = "no" ] && Screensize="${Xaxis}x${Yaxis}" ;;
  esac
  [ -z "$Maxxaxis" ] && {
    Maxxaxis="$Xaxis"
    Maxyaxis="$Yaxis"
  }
  [ "$Xaxis" -gt "$Maxxaxis" ] && Maxxaxis="$Xaxis"
  [ "$Yaxis" -gt "$Maxyaxis" ] && Maxyaxis="$Yaxis"

  command -v cvt >/dev/null && Modeline="$(cvt $Xaxis $Yaxis | tail -n1 | cut -d' ' -f2-)"
  Modeline="$(echo $Modeline | cut -d_ -f1)\" $(echo $Modeline | cut -d_ -f2- | cut -d' ' -f2-)"

  verbose "Virtual screen size: $Screensize"
  verbose "Physical screen size:
  $(xrandr 2>/dev/null | grep Screen ||:)"
  
  # create set of Modelines if needed
  { [ "$Xserver" = "--xpra" ] && [ "$Xpravfb" = "Xvfb" ] && [ "$Desktopmode" = "yes" ] ; } || [ "$Xserver" = "--xvfb" ] && {
    Modelinefile="$(create_modelinefile ${Maxxaxis}x${Maxyaxis})"
  }
      
  return 0
}