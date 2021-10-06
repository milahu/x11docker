check_xdepends() {              # check dependencies on host for X server option $1
  # Return 1 if something is missing
  local Return= Message=
  
  [ "$Lastcheckedxserver" = "${1:-}" ] && debugnote "Dependencies of ${1:-} already checked: $Lastcheckedxserverresult " && return $Lastcheckedxserverresult

  case $Autochooseserver in
    yes) Message="debugnote" ;;
    no)  Message="note" ;;
  esac
  case ${1:-} in
    --xephyr|--xpra|--nxagent|--xorg|--xvfb|--xdummy|--xwayland|--weston-xwayland|--kwin-xwayland|--xdummy-xwayland)
      command -v xinit >/dev/null || {
        $Message "${1:-}: xinit not found."
        Return=1
      }
    ;;
  esac
  case ${1:-} in
    --xpra-xwayland|--weston-xwayland|--xwayland|--weston|--kwin|--kwin-xwayland|--xdummy-xwayland|--hostwayland)
      [ "$Nvidiaversion" ] && {
        $Message "${1:-}: Closed source NVIDIA driver does not support Wayland."
        Return=1
      }
      [ "$Runtime" = "kata-runtime" ] && {
        $Message "${1:-} not supported with --runtime=kata-runtime"
        Return=1
      }
      case $Mobyvm in
        yes)
          $Message "${1:-} not supported with MobyVM / docker-for-win"
          Return=1
        ;;
      esac
    ;;
  esac
  case ${1:-} in
    --xpra|--xpra-xwayland)
      command -v "xpra" >/dev/null || {
        $Message "${1:-}: xpra not found.
  $Wikipackages"
        Return=1
      } ;;
    --xephyr)
      command -v "Xephyr" >/dev/null || command -v "Xnest" >/dev/null || {
        $Message "${1:-}: Neither Xephyr nor Xnest found.
  $Wikipackages"
        Return=1
      } ;;
    --nxagent)
      command -v "nxagent" >/dev/null || {
        $Message "${1:-}: nxagent not found.
  $Wikipackages"
        Return=1
      } ;;
    --xvfb)
      command -v "Xvfb" >/dev/null || {
        $Message "${1:-}: Xvfb not found.
  $Wikipackages"
        Return=1
      } ;;
    --xorg|--xdummy)
      command -v "Xorg" >/dev/null || {
        $Message "${1:-}: Xorg not found.
  $Wikipackages"
        Return=1
      } ;;
    --xwin)
      case "$Winsubsystem" in
        CYGWIN)
          command -v XWin >/dev/null || {
            $Message "${1:-}: XWin not found. 
  Need packages 'xinit', 'xauth' and 'xwininfo' in Cygwin (X11 section)."
            Return=1
          }
        ;;
        WSL1|WSL2)
          $Message "${1:-}: XWin is available in Cygwin on MS Windows only.
  Use runx to provide XWin in WSL:  https://github.com/mviereck/runx"
          Return=1
        ;;
        MSYS2)
          $Message "${1:-}: XWin is available in Cygwin on MS Windows only.
  With runx XWin is available in WSL, too.
  In MSYS2 you can only use runx with VcXsrv to provide an X server:
    https://github.com/mviereck/runx"
          Return=1
        ;;
        "")
          $Message "${1:-}: XWin is available in Cygwin on MS Windows only."
          Return=1
        ;;
      esac
      command -v xwininfo >/dev/null || {
        $Message "${1:-}: xwininfo not found. 
  Need 'xwininfo' package from Cygwin/X (X11 section)."
        Return=1
      }
      [ "$Hostip" ] || {
        $Message "${1:-}: Failed to get host IP address."
        Return=1
      }
    ;;
    --runx)
      [ "$Winsubsystem" ] || {
        $Message "${1:-}: runx is available on MS Windows only."
        Return=1
      }
      command -v runx >/dev/null || {
        $Message "${1:-}: runx not found. 
  Need runx from https://github.com/mviereck/runx"
        Return=1
      }
    ;;
  esac
  case ${1:-} in
    --weston|--xpra-xwayland|--weston-xwayland|--xdummy-xwayland)
      command -v "weston" >/dev/null || {
        $Message "${1:-}: weston not found.
  $Wikipackages"
        Return=1
      } ;;
    --kwin|--kwin-xwayland)
      command -v "kwin_wayland" >/dev/null || {
        $Message "${1:-}: kwin_wayland not found.
  $Wikipackages"
        Return=1
      } ;;
  esac
  case ${1:-} in
    --xpra-xwayland|--weston-xwayland|--kwin-xwayland|--xwayland|--xdummy-xwayland)
      command -v "Xwayland" >/dev/null || {
        $Message "${1:-}: Xwayland not found.
  $Wikipackages"
        Return=1
      } ;;
  esac
  case ${1:-} in
    --xpra-xwayland|--xdummy-xwayland)
      command -v "xdotool" >/dev/null || {
        $Message "${1:-}: xdotool not found.
  $Wikipackages"
        Return=1
      } ;;
  esac
  case ${1:-} in
    --xpra|--xpra-xwayland)
      [ "$Return" = "1" ] || {
        # check xpra version
        [ "$Xpraversion" ] || {
          Xpraversion="$(xpra --version 2>/dev/null | cut -d' ' -f2)"
          Xprarelease="$(echo $Xpraversion | cut -s -d- -f2)"
          verbose "Xpra version: ${Xpraversion:-XPRA_NOT_FOUND}"
          [ "$Xprahelp" ] || Xprahelp="$(xpra --help 2>/dev/null)"
        }
        ! verlte "$Xprarelease" "r18663" && verlte $Xprarelease "r19519" && {
          [ "$Sharehostipc" = "no" ] && {
            $Message "Your xpra version has a MIT-SHM bug that would force
  x11docker to share host IPC namespace. That would reduce container isolation.
  Current installed version: xpra $Xpraversion
  Please update to at least xpra v2.3.1-19519 or xpra v2.4-r19520,
  or downgrade to xpra v2.2.5 or lower, or use another X server option.
  If you insist on using current xpra, set insecure option --hostipc.
  Fallback: will search for another available X server setup."
            Return=1
          }
        }
      }
    ;;
  esac
  case ${1:-} in
    --xpra)
      [ -z "$Hostdisplay" ] && [ -n "$Hostwaylandsocket" ] && {
        verlt $Xprarelease r23305 && {
          $Message "Option ${1:-}: xpra on Wayland needs at least xpra v3.0-r23305 
  with python3 backend."
          Return=1
        } || {
          $Message "Option ${1:-}: Support in pure Wayland is experimental
  and needs latest xpra v3.x versions with python3 backend.
  If issues occur, use --weston-xwayland, --kwin-xwayland or --hostwayland
  or use option ${1:-} in an X environment."
        }
      } || {
        [ "$Hostdisplay" ] || {
          $Message "${1:-} needs a running X server. DISPLAY is empty. Wayland support is experimental option."
          Return=1
        }
      }
    ;;
    --hostdisplay|--xpra-xwayland|--xdummy-xwayland|--xephyr|--nxagent)
      [ "$Hostdisplay" ] || {
        $Message "${1:-} needs a running X server. DISPLAY is empty."
        Return=1
      }
    ;;
    --hostwayland|--xwayland)
      [ "$Hostwaylandsocket" ] || {
        $Message "${1:-} needs a running Wayland compositor. WAYLAND_DISPLAY is empty."
        Return=1
      }
    ;;
  esac
  [ "$Winsubsystem" ] && {
    case ${1:-} in
      --tty|--xwin|--runx) ;;
      --xpra|--xpra-xwayland)
        $Message "${1:-} is not supported on MS Windows."
        Return=1
      ;;
      *)
        [ -z "$Hostdisplay" ] && {
          case $Winsubsystem in
            Cygwin) $Message "${1:-} needs a running X server. DISPLAY is empty.
  Please install packages in Cygwin:  xinit xauth xwininfo
  or use runx to provide an X server on MS Windows:  
    https://github.com/mviereck/runx" ;;
            MSYS2|WSL1|WSL2) $Message "${1:-} needs a running X server. DISPLAY is empty.
  Please use runx to provide an X server on MS Windows:  
    https://github.com/mviereck/runx" ;;
          esac
          Return=1
        }
      ;;
    esac
  }
  [ "$Xoverip" = "yes" ] && {
    case ${1:-} in
      --xephyr|--xorg|--nxagent|--xpra|--xvfb|--xdummy|--xwin|--runx|--tty) ;;
      --hostdisplay)
        [ -n "$(cut -d: -f1 <<< "$Hostdisplay")" ] || {
          $Message "${1:-} does not support X over TCP
  except if started remotely with 'ssh -X'."
          Return=1
        }
      ;;
      --xwayland|--weston-xwayland|--kwin|--kwin-xwayland|--xpra-xwayland|--xdummy-xwayland|--hostwayland)
        $Message "${1:-} does not support X over TCP."
        Return=1
      ;;
    esac
  }
  [ "$Sharegpu" = "yes" ] && {
    case ${1:-} in
      --hostdisplay|--xorg|--xpra-xwayland|--weston-xwayland|--kwin-xwayland|--xdummy-xwayland|--xwayland|--xwin|--runx) ;;
      --weston|--kwin|--hostwayland) ;;
      *) 
        $Message "${1:-} does not support hardware acceleration (option --gpu)."
        Return=1
      ;;
    esac
  }
  
  Return="${Return:-"0"}"
  debugnote "Dependency check for ${1:-}: $Return"
  
  [ "$Return" = "1" ] && {
    check_fallback
    Autochooseserver="yes"
  }
  
  Lastcheckedxserver="${1:-}"
  Lastcheckedxserverresult="$Return"
  
  return "$Return"
}