check_option_interferences() {  # check multiple option interferences, change settings if needed
  local Message

  [ "$Desktopmode" = "no" ] && case $Xserver in
    --xephyr|--weston-xwayland|--kwin-xwayland|--xorg) Windowmanagermode="auto" ;;
  esac
  
  case $Xserver in
    --xorg) # check if --xorg can run
      [ "$Autochooseserver" = "yes" ] && [ "$Codename" = "xonly" ] && error "Will not run an empty Xorg in auto-choosing mode.
  If you want this, please use option --xorg explicitly."

      [ -e "/etc/X11/Xwrapper.config" ] && sed 's/ //g' /etc/X11/Xwrapper.config | grep -xq "allowed_users=anybody" && sed 's/ //g' /etc/X11/Xwrapper.config | grep -xq "needs_root_rights=yes" && {
        Xlegacywrapper="yes"
      } || {
        Xlegacywrapper="no"
        [ "$Startuser" != "root" ] && [ "$Runsonconsole" != "yes" ] && warning "Your configuration seems not to allow to start
  a second core Xorg server from within X. Option --xorg may fail.
  (Per default, only root or console users are allowed to run an Xorg server).

  Possible solutions:
  1.) Install one of nested X servers 'Xephyr', 'Xnest' or 'nxagent'.
      For --gpu support: install 'weston' and 'Xwayland'.
  2.) Switch to console tty1...tty6 with <CTRL><ALT><F1>...<F6>
      and start x11docker there.
  3.) Run x11docker as root.
  4.) Edit file '/etc/X11/Xwrapper.config' and replace line:
          allowed_users=console
      with lines
          allowed_users=anybody
          needs_root_rights=yes
      If the file does not exist already, you can create it.
      On Debian and Ubuntu you need package xserver-xorg-legacy.
      
   Be aware that switching directly between Xorg servers can crash them.
   Always switch to a black console first before switching to Xorg."
      }
    ;;
    --xpra) # check vfb for xpra
      { [ -z "$Xpravfb" ] || [ "$Xpravfb" = "Xvfb" ] ; } && ! command -v Xvfb >/dev/null && note "Option --xpra: Xvfb not found. 
  Will try to use dummy video driver Xdummy.
  If you encounter xpra startup errors, please install 'Xvfb'.
  $Wikipackages" && Xpravfb="Xdummy"
      [ "$Xpravfb" ] || { command -v Xvfb >/dev/null && Xpravfb="Xvfb" || Xpravfb="Xdummy" ; }
    ;;
    --tty)
      [ "$Interactive" = "no" ] && {
        tput lines >/dev/null 2>&1 && store_runoption env "LINES=$(tput lines)"
        tput cols  >/dev/null 2>&1 && store_runoption env "COLUMNS=$(tput cols)"
        #verbose "Option --tty: Setting LINES and COLUMNS to terminal size ${COLUMNS}x${LINES}."
      }
    ;;
    --hostdisplay)
      [ "$Winsubsystem" ] && Trusted="yes" || Trusted="no"
      [ -n "$(cut -d: -f1 <<< "$Hostdisplay")" ] && Xoverip="yes"
      [ -z "$Hostxauthority" ] && {
        note "Option --hostdisplay: You host X server seems to run
  without cookie authentication. Cannot set up a cookie for X access.
  Fallback: Enabling option --no-auth."
        check_fallback
        Xauthentication="no"
      }
      case $Xtest in
        yes|no) 
          note "Option --xtest: Cannot enable or disable X extension XTEST
  with option --hostdisplay."
          Xtest=""
        ;;
      esac
    ;;
    --xdummy|--xvfb)
      Showdisplayenvironment="yes"
    ;;
  esac
  case $Xserver in
    -xpra|--xpra-xwayland)
      # check for version with cookie bug
      ! verlt "$Xpraversion" "v2.3" && verlt "$Xprarelease" "r19606" && {
        command -v xhost >/dev/null || {
          warning "Your xpra version has a cookie authentication issue.
  also, 'xhost' is not available on your host.
  Fallback: Disabling cookie authentication on new X server."
          check_fallback
          Xauthentication="no"
        }
      } ;;
  esac

  # check if a host window manager is needed
  [ "$Desktopmode" = "no" ] && [ -z "$Windowmanagermode" ] && case $Xserver in
    --xephyr|--weston-xwayland|--kwin-xwayland|--xorg|--xwayland)
      note "Option $Xserver: x11docker assumes that you need
  a window manager. If you don't want this, run with option --desktop. 
  Enabling option --wm to provide a window manager."
      Windowmanagermode="auto"
      [ "$Autochooseserver" = "yes" ] && [ "$Runsonconsole" = "no" ] && {
        case $Sharegpu in
          no)  note "Did not find a nice solution to run a seamless application
  on your desktop. (Only insecure option --hostdisplay would work).
  It is recommended to install xpra or nxagent 
  to allow a seamless mode without the need of a window manager from host." ;;
          yes) note "Did not find a nice solution to run a seamless application with
  option --gpu on your desktop. (Only insecure option --hostdisplay would work).
  It is recommended to install xpra, weston, Xwayland and xdotool
  to allow a seamless mode without the need of a window manager from host." ;;
        esac
      }
    ;;
    *)
      Windowmanagermode="none"
    ;;
  esac

  # check xauth
  [ "$Xauthentication" = "yes" ] && case $Xserver in
    --tty) ;;
    --weston|--kwin|--hostwayland) Xauthentication="no" ;;
    *)
      command -v xauth >/dev/null || {
        case $Xoverip in
          yes)
            [ -z "$Hostxauthority" ] && [ "$Xserver" = "--hostdisplay" ] && Message=warning || Message=error
            $Message "Command 'xauth' not found.
      SECURITY RISK!
  Your X server would be accessible over network without authentication!
  That could be abused to take control over your system.
  Please install 'xauth' to allow X cookie authentication.
  You can disable cookie authentication with discouraged option --no-auth."
          ;;
          no|"")
            warning "Command 'xauth' not found.
  Please install 'xauth' to allow X cookie authentication.
  Securing X access with cookie authentication is not possible.
  Fallback: Disabling X authentication protocol. (option --no-auth)
  $Wikipackages"
          check_fallback
          ;;
        esac
        Xauthentication="no"
      }
    ;;
  esac

  # --fullscreen is nonsense on tty at all. Avoids weston error on tty.
  [ "$Runsonconsole" = "yes" ] && Fullscreen="no"
          
  # --gpu
  [ "$Sharegpu" = "yes" ] && {
    warning "Option --gpu degrades container isolation.
  Container gains access to GPU hardware.
  This allows reading host window content (palinopsia leak)
  and GPU rootkits (compare proof of concept: jellyfish)."
    case $Xoverip in
      yes)
        case $Nvidiaversion in
          "")
            [ "$Network" != "host" ] && note "Option --gpu: With X over IP the host network stack must
  be shared to allow GPU access. Enabling option --network=host."
            Network="host"
          ;;
          *)
            Iglx="yes"
          ;;
        esac
      ;;
    esac
  }

  # --hostdisplay --gpu
  [ "$Xserver" = "--hostdisplay" ] && [ "$Sharegpu" = "yes" ]  && [ "$Trusted" = "no" ] && {
    note "Option --gpu: To allow GPU acceleration with --hostdisplay,
  x11docker will allow trusted cookies."
    Trusted="yes"
  }

  # --hostdisplay with SSH
  [ "$Xserver" = "--hostdisplay" ] && [ "$Runsoverssh" = "yes" ] && {
    [ "$Trusted" = "no" ] || [ "$Network" != "host" ]  && {
      note "For SSH connection with option --hostdisplay
  x11docker must enable option --network=host and allow trusted cookies.
  It is recommended to use other X server options
  like --xpra, --xephyr or --nxagent."
      Network="host"
      Trusted="yes"
    }
  }
  
  # --hostdisplay with untrusted cookies: check xdpyinfo
  [ "$Xserver" = "--hostdisplay" ] && [ "$Trusted" = "no" ] && {
    command -v xdpyinfo >/dev/null && {
      xdpyinfo | grep -q SECURITY || {
        note "Your X server does not support untrusted cookies.
  Have to allow trusted cookies.
  Consider to use options --xpra or --nxagent instead of --hostdisplay."
        Trusted="yes"
      }
    } || note "Command 'xdpyinfo' not found. Need it to check
  whether Xorg supports untrusted cookies for --hostdisplay
  and whether extension MIT-SHM for shared memory is enabled.
  Please install 'xdpyinfo'.
  $Wikipackages"
  }
  
  # --clipboard
  case "$Shareclipboard" in
    yes)
      case $Xserver in
        --weston|--kwin) note "Sharing clipboard with $Xserver is not supported" ;;
        --hostwayland) note "Sharing clipboard may or may not work.
  Cannot enable or disable it, it depends on your Wayland compositor." ;;
        --hostdisplay)
          [ "$Trusted" = "no" ] && warning "Option --clipboard: To allow clipboard sharing with
  option --hostdisplay, trusted cookies will be enabled.
  No protection against X security leaks is left!
  Consider to use another X server option."
          Trusted="yes"
        ;;
      esac
      case $Xserver in
        --xpra|--xpra-xwayland|--hostdisplay|--kwin|--weston|--tty|--xwin) ;;
        *) note "Sharing picture clips with option --clipboard
  is only possible with options --xpra, --xpra-xwayland and --hostdisplay." ;;
      esac
    ;;
  esac
  [ "$Trusted" = "no" ] && warning "Option --hostdisplay: Clipboard isolation might fail."

  case $Containersetup in
    no)
      [ -z "$Workdir" ] && [ "$Sharehome" = "no" ] && note "Option --no-setup: You might need to specify
  e.g. '--workdir=/tmp' or '--env HOME=/tmp' to allow proper functionality."
      case $Initsystem in
        none) ;;
        tini|dockerinit) Initsystem="dockerinit" ;;
        *) note "Option --no-setup: Option --init=$Initsystem is not supported.
  Fallback: Setting --init=tini"
          Initsystem="dockerinit"
        ;;
      esac
      
      [ "$Dbusrunsession" ] && {
        note "Option --no-setup does not support option --dbus
  Fallback: Disabling option --dbus"
        Dbusrunsession="no"
      }
      [ "$Langwunsch" ] && {
        note "Option --no-setup does not support option --lang.
  Fallback: Disabling option --lang, setting '--env LANG=$Langwunsch' only."
        store_runoption env "LANG=$Langwunsch"
        Langwunsch=""
      }
      [ "$Noentrypoint" = "yes" ] && {
        note "Option --no-setup does not support option --no-entrypoint.
  Fallback: Disabling option --no-entrypoint."
        Noentrypoint="no"
      }
      [ "$Runasroot" ] && {
        note "Option --no-setup does not support option --runasroot.
  Fallback: Disabling option --runasroot."
        Runasroot=""
      }
      [ "$Runasuser" ] && {
        note "Option --no-setup does not support option --runasuser.
  Fallback: Disabling option --runasuser."
        Runasuser=""
      }
      [ "$Sudouser" ] && note "Option --no-setup does not support option --sudouser.
  Fallback: Enables needed container capabilities to allow sudo
  just in case the container user is set up for su and/or sudo.
  Consider to use --user=root."
      # --stdin?
      # --hostdbus
    ;;
  esac
  
  # --dbus [=system]
  case $Dbusrunsession in
    yes|user|session) Dbusrunsession="yes" ;;
    no) ;;
    system)
      Dbusrunsession="yes"
      Dbussystem="yes"
    ;;
    *)
      note "Option --dbus: Unknown argument '$Dbusrunsession'.
  Fallback: Enabling --dbus user session."
      check_fallback
      Dbusrunsession="yes"
    ;;
  esac
  
  # --cap-default
  [ "$Capdropall" = "no" ] && { 
    warning "Option --cap-default disables security hardening
  for containers done by x11docker. Default docker capabilities are allowed.
  This is considered to be less secure."
    case "$Allownewprivileges" in
      "yes"|"no") ;;
      "auto")
        note "Option --cap-default: Enabling option --newprivileges.
  You can avoid this with --newprivileges=no"
        Allownewprivileges="yes"
      ;;
    esac
  }
  
  # --newprivileges
  case $Allownewprivileges in
    yes|no|auto) ;;
    *) 
      note "Option --newprivileges: Unknown argument '$Allownewprivileges'.
  Fallback: Setting --newprivileges=auto"
      check_fallback
      Allownewprivileges="auto"
    ;;
  esac

  # --hostipc: Check auto-enabling
  [ "$Xserver" = "--hostdisplay" ] && [ "$Trusted" = "yes" ] && [ "$Hostmitshm" = "yes" ] && [ "$Sharehostipc" = "no" ] && [ "$Runsoverssh" = "no" ] && {
    note "Option --hostdisplay: To allow --hostdisplay with trusted cookies,
  x11docker must share host IPC namespace with container (option --hostipc)
  to allow shared memory for X extension MIT-SHM."
    Sharehostipc="yes"
  }
  
  # --keymap: XKB keyboard layout
  [ -n "$Xkblayout" ] && {
    case $Xserver in
      --kwin|--kwin-xwayland)
        [ "$Runsonconsole" = "yes" ] && note "Option --keymap does not work with option $Xserver
  if running from console."
      ;;
    esac
    [ "$Xkblayout" = "clone" ] && case $Xserver in
      --nxagent) ;;
      *) Xkblayout="" ;;
    esac
  }

  # --scale
  [ "$Scaling" ] && {
    case $Xserver in
      --weston|--weston-xwayland)
        [[ $Scaling =~ ^[1-9]$ ]] || {
          note "The scale factor for option $Xserver must be
  one of   1  2  3  4  5  6  7  8  9
  Fallback: disabling option --scale"
          check_fallback
          Scaling=""
        }
      ;;
      --xpra|--xpra-xwayland|--xorg)
        isnum $Scaling || {
          note "Option --scale needs a number. '$Scaling' is not allowed.
  Fallback: disabling option --scale"
          check_fallback
          Scaling=""
        }
      ;;
      *)
        note "Option $Xserver does not support option --scale.
  Available for --xpra, --xpra-xwayland and --xorg (float values possible)
  and for --weston and --weston-xwayland (full integer values only).
  Fallback: disabling option --scale"
        check_fallback
        Scaling=""
      ;;
    esac
    case $Xserver in
      --xpra|--xpra-xwayland)
        verlt "$Xpraversion" "v0.16" && {
          note "Your xpra version is quite old and does not support --scale.
  You need at least xpra version 0.16
  Fallback: disabling option --scale"
          check_fallback
          Scaling=""
        }
      ;;
    esac
    case $Xserver in
      --weston-xwayland) note "Weston does not work well with Xwayland in scaled mode.
  In summary, Xwayland does not get the right screen resolution from Weston.
  (Bug report at https://bugzilla.redhat.com/show_bug.cgi?id=1498669 ).
  Try out if it works for you. Otherwise, you can combine
  '--xpra-xwayland --desktop --scale $Scaling' for better desktop scaling support.
  --scale for single applications works best with --xpra / --xpra-xwayland.
  --scale in desktop mode works best with option --xorg."
      ;;
      --xpra-xwayland)
        [ "1" = "$(awk -v a="${Scaling:-1}" 'BEGIN {print (a < 1)}')" ] && {
          command -v weston >/dev/null || {
            note "Option --xpra-xwayland needs weston
  for scale factor smaller than 1.
  Fallback: disabling option --scale"
            check_fallback
            Scaling=""
          }
        }
      ;;
      --xorg)
        [ "1" = "$(awk -v a="$Scaling" 'BEGIN {print (a < 1)}')" ] && [ -n "$Rotation" ] && note "--xorg does not work well with combination
  of --scale smaller than 1 and rotation different from 0."
      ;;
    esac
  }

  # --rotate
  [ -n "$Rotation" ] && {
    case $Xserver in
      --weston|--weston-xwayland|--xorg)
        echo "0 90 180 270 flipped flipped-90 flipped-180 flipped-270" | grep -q "$Rotation" || {  # fuzzy test, have been lazy
          note "Unsupported value '$Rotation' for option --rotate.
  Must be one of 0 90 180 270 flipped flipped-90 flipped-180 flipped-270
  Fallback: disabling option --rotate"
          check_fallback
          Rotation=""
        }
      ;;
      *)
        note "Option $Xserver does not support option --rotate.
  Rotation is possible for --xorg, --weston and --weston-xwayland.
  Fallback: disabling option --rotate"
        check_fallback
        Rotation=""
      ;;
    esac
  }
  [ "$Rotation" = "0" ] && Rotation="normal"

  # xrandr: --scale --size --rotate
  command -v xrandr >/dev/null || case $Xserver in
    --xorg) { [ "$Scaling" ] || [ -n "$Rotation" ] || [ -n "$Screensize" ] ; } && note "Option --xorg needs 'xrandr' to support
  options --size, --scale and --rotate.
  Please install 'xrandr'.
  $Wikipackages"
    ;;
  esac

  # --dpi
  [ -n "$Dpi" ] && case $Xserver in
    --weston|--kwin|--hostwayland|--hostdisplay)
      note "Option --dpi has no effect with option $Xserver"
      Dpi=
    ;;
  esac

  # --output-count
  [ "$Outputcount" != "1" ] && {
    case $Xserver in
      --xephyr|--weston|--kwin|--weston-xwayland|--kwin-xwayland|--xwin)
        [[ "$Outputcount" =~ ^[1-9]$ ]] || {
          note "Option --output-count: Value must be one of 1 2 3 4 5 6 7 8 9
  Disabling invalid value $Outputcount"
          Outputcount="1"
        }
        [ "$Runsonconsole" = "yes" ] && {
          note "Option --outputcount only works in nested/windowed mode,
  but not on tty. Fallback: disabling --outputcount"
          check_fallback
          Outputcount="1"
        }
      ;;
      *) note "$Xserver does not support option --output-count.
  Only available for Weston, KWin and Xephyr, thus for options
  --weston, --weston-xwayland, --kwin, --kwin-xwayland, --xephyr."
        Outputcount="1"
      ;;
    esac
  }

  # --xfishtank: fish tank
  [ "$Xfishtank" = "yes" ] && {
    command -v xfishtank >/dev/null || {
      note "xfishtank not found. Can not show a fish tank.
  Please install 'xfishtank' for option --xfishtank to show a fish tank.
  $Wikipackages"
      Xfishtank="no"
    }
    case $Xserver in
      --xpra|--xpra-xwayland|--nxagent)
        [ "$Desktopmode" = "no" ] && [ -z "$Windowmanagermode" ] && Windowmanagermode="auto" && Desktopmode="yes" ;;
      --weston|--kwin|--hostwayland|--hostdisplay|--tty)
        note "Option --xfishtank is not supported for $Xserver."
        Xfishtank="no"
      ;;
    esac
  }
  
  # MSYS2, Cygwin, WSL
  case $Winsubsystem in
    WSL2) note "WSL2 support is experimental and barely tested yet. 
  Feedback and bug reports are appreciated!" ;;
  esac
  case $Mobyvm in
    yes)
      case "$Winsubsystem" in
        WSL1|WSL2)
          grep -q "/c/" <<< "$Cachebasefolder" && [ -z "$Hosthomebasefolder" ] && note "With MobyVM and WSL x11docker stores its cache files on drive C:
  to allow cache file sharing.
  Your Docker setup might not allow to share files from drive C:.
  If startup fails with an 'access denied' error,
  please either allow access to drive C: or specify a custom folder for
  cache storage with option '--cachebasedir D:/some/cache/folder'.
  Same issue can occur with option '--home'. 
  Use option '--homebasedir D:/some/home/folder' in that case."
        ;;
      esac
      [ "$Initsystem" = "systemd" ] && {
        note "Option --init=systemd is not supported with MobyVM.
  You can try another init option instead, e.g. --init=openrc.
  Fallback: Disabling option --init=systemd"
        check_fallback
        Initsystem="tini"
      } 
      [ "$Sharecgroup" = "yes" ] && { 
        note "Option --sharecgroup is not supported with MobyVM.
  Fallback: Disabling option --sharecgroup."
        Sharecgroup="no"
      }
    ;;
  esac
  case $Winsubsystem in
    MSYS2|CYGWIN|WSL1|WSL2)
      [ "$Pulseaudiomode" ] && {
        note "Option --pulseaudio is not supported on MS Windows.
  Fallback: Disabling option --pulseaudio"
        check_fallback
        Pulseaudiomode=""
      }
      case $Xserver in
        --xwin) note "Windows firewall settings can forbid application access
  to the X server. If no application window appears, but no obvious error
  is shown, please check your firewall settings. Compare issue #108 on github." ;;
      esac
    ;;
  esac
    
  # check XDG_RUNTIME_DIR
  case $Xserver in
    --weston|--kwin|--weston-xwayland|--kwin-xwayland) 
      [ -z "$XDG_RUNTIME_DIR" ] && [ -e "/run/user/${Hostuseruid:-unknownuid}" ] && export XDG_RUNTIME_DIR="/run/user/$Hostuseruid"
      [ -z "$XDG_RUNTIME_DIR" ] && {
        export XDG_RUNTIME_DIR="$Cachefolder/XDG_RUNTIME_DIR"
        unpriv "mkdir -p  $XDG_RUNTIME_DIR"
        unpriv "chmod 700 $XDG_RUNTIME_DIR"
      }
    ;;
  esac
  
  # --wayland
  [ "$Setupwayland" = "yes" ] && case $Xserver in
    --weston|--kwin|--hostwayland) ;;
    *) 
      note "Option --wayland: Sharing Wayland socket is not supported
  for X server option $Xserver.
  You can try --weston, --kwin or --hostwayland instead.
  Fallback: Disabling option --wayland."
      check_fallback
      Setupwayland="no"
    ;;
  esac
  [ "$Setupwayland" = "yes" ] && {
    Dbusrunsession="yes"
    for Line in $Waylandtoolkitenv; do
      store_runoption env $Line
    done
  }

  # check --westonini
  [ -n "$Customwestonini" ] && [ ! -e "$Customwestonini" ] && {
    warning "Custom weston.ini (option --westonini) not found.
  $Customwestonini"
    Customwestonini=""
  }
  
  # --interactive
  case $Interactive in
    yes)
      case $Winsubsystem in
        MSYS2|CYGWIN|WSL1)
          Winpty="$(command -v winpty)"
          Winpty="$(escapestring "$Winpty")"
          [ "$Winpty" ] || error "Option -i, --interactive: On MS Windows you need 'winpty'
  to run x11docker in interactive mode. MSYS2 provides winpty as a package.
  On Cygwin it can be compiled from source. WSL1 isn't supported yet.
  WSL2 might work, but is not tested yet."
        ;;
      esac
      [ "$Forwardstdin" = "yes" ] && {
        note "You cannot use --stdin along with --interactive.
  Fallback: Disabling option --stdin."
        check_fallback
        Forwardstdin="no"
      }
      [ "$Runsinteractive" = "yes" ] && {
        note "Option -i, --interactive: Does not work in interactive
  bash mode (option --enforce-i).
  Fallback: Disabling option --interactive."
        check_fallback
        Interactive="no"
      }
      case $Initsystem in
        systemd|openrc|runit|sysvinit)  note "Option --interactive: Interactive mode with option
  --init=$Initsystem is not well integrated yet. 
  Shells do not have job control and CTRL-C can behave different than expected." ;;
      esac
    ;;
  esac
  [ "$Interactive" = "yes" ] && Showcontaineroutput="no"
  
  # --limit N
  [ "$Limitresources" ] && {
    [ "1" = "$(awk -v a=$Limitresources "BEGIN {print (a <= 1)}")" ] && [ "1" = "$(awk -v a=$Limitresources "BEGIN {print (a > 0)}")" ] || {
      warning "Option --limit: Specified value $Limitresources is out of range.
  Allowed is a factor greater than 0 and less than or equal to 1.  0<FACTOR<=1
  Fallback: Setting limit factor to --limit=0.5"
      check_fallback
      Limitresources="0.5"
    }
    note "Option --limit does not avoid possibly flooding the hard disk
  in docker's container partition or in shared folders.
  It only restricts memory and CPU usage."
  }
  
  # --pulseaudio
  case $Pulseaudiomode in
    "") ;;
    auto|tcp|socket) 
      command -v pactl >/dev/null || {
        note "Option --pulseaudio: pactl not found.
  Is pulseaudio installed and running on your host system?
  Fallback: Disabling --pulseaudio, enabling option --alsa"
        check_fallback
        Pulseaudiomode=""
        Sharealsa="yes"
      }
    ;;
    *) 
      note "Option --pulseaudio: Unknown pulseaudio mode: $Pulseaudiomode
  Allowed are --pulseaudio=socket, --pulseaudio=tcp or --pulseaudio=auto.
  Fallback: Enabling --pulseaudio=auto"
      check_fallback
      Pulseaudiomode="auto"
    ;;
  esac
  
  # --printer
  case $Sharecupsmode in
    auto)
      Sharecupsmode="socket"
      [ "$Snapsupport" = "yes" ]      && Sharecupsmode="tcp"
      [ "$Runtime" = "kata-runtime" ] && Sharecupsmode="tcp"
    ;;
    ""|socket|tcp) ;;
    *) 
      note "Option --printer: Invalid argument $Sharecupsmode
  Fallback: Setting --printer=socket"
      check_fallback
      Sharecupsmode="socket"
    ;;
  esac
  
  # --pull
  case "$Pullimage" in
    yes|no|always|ask) ;;
    *) note "Option --pull: Invalid argument: $Pullimage
  Allowed arguments: yes|no|always|ask
  Fallback: Setting --pull=ask" 
      check_fallback
    ;;
  esac
  
  case "$Runtime" in
    ""|runc|crun|oci) ;;
    nvidia) Sharegpu="yes" ;;
    kata-runtime)
      note "Option --runtime=kata-runtime: Be aware not to share
  the same files with runc and kata-runtime containers at the same time.
  Otherwise container startup may fail."
      [ "$Sharealsa" = "yes" ] && {
        note "Option --alsa: ALSA sound is not possible with 
  --runtime=kata-runtime. Fallback: Enabling option --pulseaudio."
        check_fallback
        Sharealsa="no"
        Pulseaudiomode="tcp"
      }
      [ "$Sharewebcam" = "yes" ] && {
        note "Option --webcam: Webcam support does not work with
  --runtime=kata-runtime. Fallback: Disabling option --webcam."
        check_fallback
        Sharewebcam="no"
      }
      [ "$Network" = "host" ] && {
        note "Option --network=host: Sharing host network stack does not work
  with --runtime=kata-runtime. Fallback: Setting --network=bridge."
        check_fallback
        Network="bridge"
      }
      [ "$Sharegpu" = "yes" ] && [ -z "$Nvidiaversion" ] && {
        note "Option --runtime=kata currently does not support option --gpu 
  except with closed source NVIDIA driver.
  Fallback: Disabling option --gpu"
        check_fallback
        Sharegpu="no"
      }
      [ "$Sharehostipc" = "yes" ] && {
        note "Option --hostipc: Only IPC of the qemu VM is shared with
  --runtime=kata-runtime."
      }
    ;;
    *)
      note "Option --runtime: x11docker does not know runtime: $Runtime"
    ;;
  esac
  
  # --home rootless
  [ "$Rootlessbackend" ] && {
    case $Containerbackend in
      docker|nerdctl)
        [ "$Sharehome" ] && {
          note "Option --home is not supported in $Containerbackend rootless mode.
  In rootless mode only option --backend=podman supports option --home.
  Alternatively run one of docker, podman or nerdctl in rootful mode.
  Fallback: Disabling option --home"
          check_fallback
          Sharehome="no"
        }
      ;;
    esac
  }

  Sudouser="${Sudouser,,}"
  case $Sudouser in
    no|"") Sudouser="" ;;
    yes|nopasswd) ;;
    *) 
      note "Option --sudouser: Unknown argument '$Sudouser'.
  Fallback: Disabling option --sudouser."
      Sudouser=""
      check_fallback
    ;;
  esac

  case "$Containerbackend" in
    docker) ;;
    podman)
      # /proc/sys/kernel/unprivileged_userns_clone might exist on debian only.
      # https://github.com/mviereck/x11docker/issues/255#issuecomment-758014962
      [ "$(cat /proc/sys/kernel/unprivileged_userns_clone)" = "0" ] && error "Option --podman: Linux kernel disallows unprivileged 
  user namespace setup. Please run as root:
    sysctl -w kernel.unprivileged_userns_clone=1"
      store_runoption cap "CHOWN"
    ;;
    nerdctl) 
      note "Option --backend=nerdctl: nerdctl only supports a subset
  of docker options. That limits support of x11docker features."
      Switchcontaineruser="yes"
      [ "$Capdropall" = "yes" ] && warning "Option --backend=nerdctl: x11docker
  will allow some user switching capabilities that would be dropped with
  other backends. (Because 'nerdctl --exec' does not support option --user.)
  Though, these are still within nerdctl default capabilities."
    ;;
    *) note "Option --backend=$Containerbackend: Unknown backend. Will try anyway.
  You might need option --no-setup. 
  Known backends are docker, podman and nerdctl." ;;
  esac
  
  return 0
}