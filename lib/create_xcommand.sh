create_xcommand() {             ### create command to start X server and/or Wayland compositor
  local Xserveroptions_custom= Xpraoptions= Nxagentoptions= Compositorpid= Weston= Westonoutput= Count= Envvar=

  Xserveroptions_custom="$Xserveroptions"
  Xserveroptions=""
  
  #### General X server options
  case $Xserver in
    --nxagent)
      { [ "$Sharehostipc" = "yes" ] || [ "$X11dockermode" = "exe" ] ; } && {
        Xserveroptions="$Xserveroptions \\
  -shmem \\
  -shpix"
      } || {
        Xserveroptions="$Xserveroptions \\
  -noshmem \\
  -noshpix"
      }
    ;;
    *) Xserveroptions=" \\
  -retro \\
  +extension RANDR \\
  +extension RENDER \\
  +extension GLX \\
  +extension XVideo \\
  +extension DOUBLE-BUFFER \\
  +extension SECURITY \\
  +extension DAMAGE \\
  +extension X-Resource \\
  -extension XINERAMA -xinerama"
      case $Sharehostipc in
        yes) Xserveroptions="$Xserveroptions \\
  +extension MIT-SHM" ;;
        no)
          Xserveroptions="$Xserveroptions \\
  -extension MIT-SHM"
          Xprashm="XPRA_XSHM=0" ;;
      esac
    ;;
  esac

  # X extension COMPOSITE
  [ "$Xcomposite" ] || case $Xserver in
    --nxagent|--xwin) Xcomposite="no" ;;
    *) Xcomposite="yes" ;;
  esac
  case $Xcomposite in
    yes)
      # Old X servers have extension "Composite", recent ones call it "COMPOSITE".
      Xserveroptions="$Xserveroptions \\
  +extension Composite +extension COMPOSITE"
    ;;
    no)
      Xserveroptions="$Xserveroptions \\
  -extension Composite -extension COMPOSITE" 
      [ "$Xserver" = "nxagent" ] && Xserveroptions="Xserveroptions \\
  -nocomposite"
    ;;
  esac

  # X extension XTEST
  [ "$Xtest" ] || case $Xserver in
    --xpra|--xpra-xwayland|--xdummy|--xdummy-xwayland|--xvfb) Xtest="yes" ;;
    *) Xtest="no" ;;
  esac
  case "$Xtest" in
    yes) Xserveroptions="$Xserveroptions \\
  +extension XTEST" ;;
    no)  Xserveroptions="$Xserveroptions \\
  -extension XTEST -tst" ;;
  esac
  
  # Disable screensaver
  Xserveroptions="$Xserveroptions \\
  -dpms \\
  -s off"

  # X cookie authentication
  case $Xauthentication in
    yes)
      Xserveroptions="$Xserveroptions \\
  -auth $Xservercookie" ;;
    no) 
      case $Xoverip in
        yes) warning "Option --no-auth: SECURITY RISK!
  Allowing access to new X server for everyone.
  Your X server is accessible over TCP network without any restriction.
  That can be abused to take control over your system." ;;
        no|"") 
          case "$Xserver" in
            --hostdisplay|--hostwayland|--weston|--kwin) ;;
            *) 
              warning "Option --no-auth: SECURITY RISK!
  Allowing access to new X server for everyone."
              Xserveroptions="$Xserveroptions \\
  -ac"
            ;;
          esac
        ;;
      esac
    ;;
  esac

  # X over IP/TCP
  case $Xoverip in
    yes) 
      case $Xserver in
        --nxagent) ;;
        *) Xserveroptions="$Xserveroptions \\
  -listen tcp" ;;
      esac
    ;;
    no|"") Xserveroptions="$Xserveroptions \\
  -nolisten tcp" ;;
  esac

  # check DPI
  case $Xserver in
    --xpra|--xpra-xwayland)
      { [ -n "$Dpi" ] || [ "$Scaling" ] ; } && verlt "$Xpraversion" "v2.1-r16547" && ! verlt "$Xpraversion" "v2.1" && {
        note "Option --dpi is buggy in xpra $Xpraversion
  due to xpra bug #1605. Need at least xpra v2.1-r16547 or one of 2.0 series.
  This affects option --scale, too, leading to wrong font sizes.
  Fallback: disabling dpi settings."
        check_fallback
        Dpi="-1"
      } ;;
  esac
  case $Xserver in
    --weston|--kwin|--tty|--hostdisplay) ;;
    --xwin|--runx) ;;
    *)
      [ -z "$Dpi" ] && {
        xdpyinfo >/dev/null 2>&1 && {
          Dpi="$(xdpyinfo | grep dots | cut -dx -f2 | cut -d' ' -f1)"
        } || {
          [ -n "$Hostdisplay" ] && [ -z "$(command -v xdpyinfo)" ] && note "Could not determine dpi settings. If you encounter too big or
  too small fonts with $Xserver, please install xdpyinfo or use option --dpi.
  $Wikipackages"
        }
        case $Xserver in
          --xpra|--xpra-xwayland)
            [ "$Scaling" ] && [ "$Desktopmode" = "no" ] && {
              Dpi="$(awk -v a="$Scaling" -v b="$Dpi" 'BEGIN {print (b * a * a)}')"
              Dpi="${Dpi%.*}"
            } ;;
        esac
      }
    ;;
  esac
  [ "$Dpi" = "-1" ] && Dpi=""
  [ -n "$Dpi" ] && Xserveroptions="$Xserveroptions \\
  -dpi $Dpi"

  
  #### xpra server and client command
  case $Xserver in
    --xpra|--xpra-xwayland)

      Xpraoptions="\\
  $(check_xpraoption --csc-modules=none) \\
  $(check_xpraoption --encodings=rgb) \\
  $(check_xpraoption --microphone=no) \\
  $(check_xpraoption --notifications=no) \\
  $(check_xpraoption --pulseaudio=no) \\
  $(check_xpraoption --socket-dirs="'$Cachefolder'") \\
  $(check_xpraoption --speaker=no) \\
  $(check_xpraoption --start-via-proxy=no) \\
  $(check_xpraoption --webcam=no) \\
  $(check_xpraoption --xsettings=no)"
#  $(check_xpraoption --clipboard-direction=both) \\
#  $(check_xpraoption --system-tray=yes) \\
      
      # --keymap
      [ "$Xkblayout" ] && Xpraoptions="$Xpraoptions \\
  $(check_xpraoption --keyboard-layout="'$Xkblayout'") \\
  $(check_xpraoption --keyboard-raw=yes)"
  
#      Xpraoptions="$Xpraoptions  $(check_xpraoption --debug=all)" ; Preservecachefiles="yes"  # Debugging only
  
      # xpra server command
      [ "$Desktopmode" = "yes" ] && Xpraservercommand="xpra start-desktop" || Xpraservercommand="xpra start"
      Xpraservercommand="$Xpraservercommand :$Newdisplaynumber --use-display $Xpraoptions \\
  $(check_xpraoption --clipboard=yes)\\
  $(check_xpraoption --dbus-proxy=no) \\
  $(check_xpraoption --daemon=no) \\
  $(check_xpraoption --fake-xinerama=no) \\
  $(check_xpraoption --file-transfer=off) \\
  $(check_xpraoption --html=off) \\
  $(check_xpraoption --opengl=noprobe) \\
  $(check_xpraoption --mdns=no) \\
  $(check_xpraoption --printing=no) \\
  $(check_xpraoption --session-name="'$Codename'") \\
  $(check_xpraoption --start-new-commands=no) \\
  $(check_xpraoption --systemd-run=no) \\
  $(check_xpraoption --video-encoders=none)"
      # disable --dpi for buggy versions
      [ -n "$Dpi" ] && verlt "$Xpraversion" "v2.1-r16547" && ! verlt "$Xpraversion" "v2.1" &&  Dpi=""
      [ -n "$Dpi" ] && Xpraservercommand="$Xpraservercommand \\
  $(check_xpraoption --dpi="'$Dpi'")"

      # xpra client command
      Xpraclientcommand="xpra attach :$Newdisplaynumber $Xpraoptions \\
  $(check_xpraoption --clipboard=$Shareclipboard) \\
  $(check_xpraoption --compress=0) \\
  $(check_xpraoption --modal-windows=no) \\
  $(check_xpraoption --opengl=auto) \\
  $(check_xpraoption --quality=100) \\
  $(check_xpraoption --video-decoders=none)"
      [ "$Fullscreen" = "yes" ]  && Xpraclientcommand="$Xpraclientcommand \\
  $(check_xpraoption --desktop-fullscreen=yes)"
      [ "$Scaling" ] && Xpraclientcommand="$Xpraclientcommand \\
  $(check_xpraoption --desktop-scaling="'$Scaling'")"
#      [ -n "$Dpi" ] && Xpraclientcommand="$Xpraclientcommand \\
#  $(check_xpraoption --dpi="'$Dpi'")"
      [ "$Xpraborder" ] && Xpraclientcommand="$Xpraclientcommand \\
  $(check_xpraoption --border="$Xpraborder")"
      [ "$X11dockermode" = "run" ] && {
        case "$Desktopmode" in
          yes) Xpraclientcommand="$Xpraclientcommand \\
  $(check_xpraoption --title="'$Codename on $Newdisplay [in container] (shift+F11 toggles fullscreen)'")" ;;
          no)  Xpraclientcommand="$Xpraclientcommand \\
  $(check_xpraoption --title="'@title@ [in container]'")" ;;
        esac
      }
  
      # xpra environment variables
      for Line in $Xpracontainerenv; do
        store_runoption env "$Line"
      done
    ;;
  esac

  
  #### Prepare weston.ini: config file for Weston
  case $Xserver in
    --weston|--weston-xwayland|--xpra-xwayland|--xdummy-xwayland)
      command -v weston-launch >/dev/null && [ "$Runsonconsole" = "yes" ] && [ "$Runsinteractive" = "yes" ] && Weston="weston-launch -v --" || Weston="weston"
      echo "[core]
shell=desktop-shell.so
idle-time=0
[shell]
panel-location=none
panel-position=none
locking=false
background-color=0xff002244
animation=fade
startup-animation=fade
[keyboard]
" >> "$Westonini"
      # --keymap: keyboard layout
      [ -n "$Xkblayout" ] && echo "keymap_layout=$Xkblayout" >> "$Westonini"
      [ -z "$Xkblayout" ] && [ "$Runsonconsole" = "yes" ] && echo "$(echo -n "keymap_layout=" && grep XKBLAYOUT <"/etc/default/keyboard" | cut -d= -f2 | cut -d'"' -f2)" >> "$Westonini"
      
      case $Runsonconsole in
        no)   # Display prefix X or WL; needed to indicate if host Wayland or host X provides the nested window.
          #[ -n "$Hostwaylandsocket" ] && [ "$Xserver" != "--xpra-xwayland" ] && [ "$Hostsystem" != "ubuntu" ] && [ "$Fullscreen" = "no" ] && Westonoutput="WL"
          [ -n "$Hostdisplay" ] && Westonoutput="X"
          [ -z "$Westonoutput" ] && [ -n "$Hostwaylandsocket" ] && Westonoutput="WL"
        ;;
        yes)  # short start&stop of Weston to grep name of monitor. Needed instead of WL or X prefix
          [ -n "$Screensize" ] || [ "$Scaling" ] || [ -n "$Rotation" ] && {
            Westonoutput="$(weston_getoutputname)"
            debugnote "$Xserver: Detected screen output for weston: $Westonoutput"
          }
        ;;
      esac
    ;;
  esac

  
  #### create command to run X server
  case $Xserver in
    --xorg)
      Xserveroptions="$Xserveroptions \\
  -verbose"
      [ "$Xorgconf" ] && Xserveroptions="$Xserveroptions \\
  -config '$Xorgconf'"       # --xorgconf
      [ "$Runsonconsole" = "yes" ] && Xserveroptions="$Xserveroptions \\
  -keeptty"
      Xcommand="$(command -v Xorg) :$Newdisplaynumber vt$Newxvt $Xserveroptions"
    ;;

    --xpra)
      case $Xpravfb in
        Xvfb) Xcommand="$(command -v Xvfb) :$Newdisplaynumber $Xserveroptions \\
  -screen 0 ${Maxxaxis}x${Maxyaxis}x24" ;;
        Xdummy) Xcommand="$Xorgwrapper :$Newdisplaynumber $Xserveroptions \\
  -config $Xdummyconf \\
  vt128" ;;
      esac
    ;;

    --xdummy)
      Xcommand="$Xorgwrapper :$Newdisplaynumber vt128 $Xserveroptions \\
  -config $Xdummyconf"
    ;;

    --xvfb)
      Xcommand="$(command -v Xvfb) :$Newdisplaynumber $Xserveroptions \\
  -screen 0 ${Screensize}x24"   ### FIXME: hardcoded setting of depth 24. Could be better?
    ;;

    --xephyr)
      command -v Xephyr >/dev/null && {
        Xserveroptions="$Xserveroptions \\
  -resizeable \\
  -noxv"
#        Xserveroptions="$Xserveroptions \\  
#  -glamor"  # disabled because of lagginess reported in #196
        case $Fullscreen in
          yes) 
            Xserveroptions="$Xserveroptions \\
  -fullscreen" 
          ;;
          no)  
            grep -q -- "-output " <<< "$Xserveroptions_custom" || Xserveroptions="$Xserveroptions \\
  -screen $Screensize"
          ;;
        esac
        Xcommand="$(command -v Xephyr) :$Newdisplaynumber $Xserveroptions"
      } || {
        # Fallback: Xnest
        Xcommand="$(command -v Xnest) :$Newdisplaynumber $Xserveroptions \\
  -geometry $Screensize \\
  -scrns $Outputcount \\
  -name '$Codename on $Newdisplay' "
        note "Option --xephyr: Xephyr not found. Fallback: using Xnest.
  Xnest is less stable and has less features than Xephyr.
  For example, it misses RandR and Composite extensions and fullscreen mode.
  It is recommended to install 'Xephyr'.
  $Wikipackages"
        check_fallback
      }
    ;;

    --xwayland)
      Xcommand="$(command -v Xwayland) :$Newdisplaynumber $Xserveroptions"
    ;;

    --xpra-xwayland|--xdummy-xwayland)
      Xcommand="$(command -v Xwayland) :$Newdisplaynumber $Xserveroptions"
  
      echo "[output]
name=${Westonoutput}1
mode=$Screensize" >> $Westonini
      [ -n "$Customwestonini" ] && Westonini="$Customwestonini"
      
      Compositorcommand="$Weston \\
  --socket=$Newwaylandsocket \\
  --backend=x11-backend.so \\
  --config='$Westonini'"
      [ "$Xserver" = "--xpra-xwayland" ] && case $Scaling in
        "") Compositorcommand="$Compositorcommand \\
  --fullscreen" ;;
        *)  Compositorcommand="$Compositorcommand \\
  --width=$(cut -dx -f1 <<< "$Screensize") --height=$(cut -dx -f2 <<< "$Screensize")" ;;
      esac
    ;;

    --weston|--weston-xwayland)
      Xcommand="$(command -v Xwayland) :$Newdisplaynumber $Xserveroptions"
  
      [ -n "$Westonoutput" ] && for ((Count=1 ; Count<="$Outputcount" ; Count++)) ; do
        [ "$Westonoutput" = "WL" ] || [ "$Westonoutput" = "X" ] || {
          Count=""
          [ -z "$Screensize" ] && Screensize="preferred"
        }
        echo "[output]
name=$Westonoutput$Count
mode=$Screensize
" >> $Westonini
        [ "$Scaling" ]        && echo "scale=$Scaling"      >> $Westonini
        [ -n "$Rotation" ]    && echo "transform=$Rotation" >> $Westonini
        [ "$Count" ] || break
      done
      
      Compositorcommand="$Weston \\
  --socket=$Newwaylandsocket"
      [ "$Fullscreen" = "yes" ] && Compositorcommand="$Compositorcommand \\
  --fullscreen"
      [ "$Outputcount" = "1" ]  || Compositorcommand="$Compositorcommand \\
  --output-count=$Outputcount"
      case $Westonoutput in
        WL) Compositorcommand="$Compositorcommand \\
  --backend=wayland-backend.so" ;;
        X)  Compositorcommand="$Compositorcommand \\
  --backend=x11-backend.so" ;;
        *)
          case "$Runsonconsole" in
            yes) Compositorcommand="$Compositorcommand \\
  --backend=drm-backend.so" ;;
            no)  Compositorcommand="$Compositorcommand \\
  --backend=x11-backend.so" ;;
          esac
        ;;
      esac
      [ -n "$Customwestonini" ] && Westonini="$Customwestonini"
      Compositorcommand="$Compositorcommand \\
  --config='$Westonini'"
    ;;

    --kwin|--kwin-xwayland)
      Xcommand="$(command -v Xwayland) :$Newdisplaynumber $Xserveroptions"
  
      Compositorcommand="kwin_wayland \\
  --xwayland \\
  --socket=$Newwaylandsocket \\
  --width=$Xaxis --height=$Yaxis"
      [ "$Outputcount" = "1" ] || Compositorcommand="$Compositorcommand \\
  --output-count=$Outputcount"
      [ "$Xkblayout" ] && Compositorcommand="KWIN_XKB_DEFAULT_KEYMAP=$Xkblayout $Compositorcommand"
      Compositorcommand="env QT_XKB_CONFIG_ROOT=/usr/share/X11/xkb $Compositorcommand"
      case $Runsonconsole in
        yes) Compositorcommand="$Compositorcommand \\
  --drm" ;;
        no)  
          kwin_wayland --help | grep -q -- '--windowed' && {
           Compositorcommand="$Compositorcommand \\
  --windowed"  
          } || {
            kwin_wayland --help | grep -q -- '--x11-display' && [ "$Hostdisplay" ] && Compositorcommand="$Compositorcommand \\
  --x11-display=$Hostdisplay"
          };;
      esac
    ;;

    --nxagent)
      # files needed by nxagent
      export NXAGENT_KEYSTROKEFILE="$Nxagentkeysfile"
      export NX_CLIENT="$Nxagentclientrc"
      
      Xserveroptions="$Xserveroptions \\
  -norootlessexit \\
  -ac \\
  -options $Nxagentoptionsfile \\
  -keystrokefile $NXAGENT_KEYSTROKEFILE"
      case $Desktopmode in
        "yes") Xserveroptions="$Xserveroptions \\
  -D \\
  -name '$Imagename on $Newdisplay (shift+F11 toggles fullscreen)'" ;;
        "no")  Xserveroptions="$Xserveroptions \\
  -R" ;;
      esac
      Xcommand="$(command -v nxagent) :$Newdisplaynumber $Xserveroptions"

      # Some additional nxagent options are stored in a file
      Nxagentoptions="nx/nx"
      [ "$Shareclipboard" = "yes" ] && Nxagentoptions="$Nxagentoptions,clipboard=both" || Nxagentoptions="$Nxagentoptions,clipboard=none"
      case $Fullscreen in
        yes) Nxagentoptions="$Nxagentoptions,fullscreen=1" ;;
        no)  [ -n "$Screensize" ] && Nxagentoptions="$Nxagentoptions,geometry=$Screensize" ;;
      esac
      
      # --composite
      case $Xcomposite in
        yes) Nxagentoptions="$Nxagentoptions,composite=1" ;;
        no)  Nxagentoptions="$Nxagentoptions,composite=0" ;;
      esac
      
      # set keyboard layout
      case $Xkblayout in
        "") # set layout from host.
          command -v setxkbmap >/dev/null && {
            Nxagentoptions="$Nxagentoptions,keyboard=$(setxkbmap -query | grep rules | awk '{print $2}')/$(setxkbmap -query | grep layout | awk '{print $2}')"
          } || note "Could not check your keyboard layout due to missing setxkbmap
  If you get mismatching keys, please install setxkbmap.
  $Wikipackages"
        ;;
        *) # --keymap
          case $Xkblayout in
            clone) Nxagentoptions="$Nxagentoptions,keyboard='clone'" ;;
            *)     Nxagentoptions="$Nxagentoptions,keyboard='evdev/$Xkblayout'" ;;
          esac
        ;;
      esac
      
      Nxagentoptions="${Nxagentoptions}:${Newdisplaynumber}"
      echo "$Nxagentoptions" >> "$Nxagentoptionsfile"
      debugnote "$Xserver: Additional nxagent options: $Nxagentoptions"
      
      # Workaround as nxagent ignores XAUTHORITY and fails to start if option -auth is given without containing the cookie from host display. 
      # Option -ac above complies "xhost +" and is reverted in xinitrc.
      [ "$Xauthentication" = "yes" ] && unpriv "cp '$Hostxauthority' '$Xservercookie'"
        
      # fake NXclient
      echo '#! /usr/bin/env bash
# helper script to terminate nxagent.
# nxagent runs program noted in NX_CLIENT if window close button is pressed.
# (real nxclient does not exist)
echo "NXclient: $*" >> '$Xinitlogfile'
parsed="$(getopt --options="" --longoptions="parent:,display:,dialog:,caption:,window:,message:" -- "$@")"
eval set -- $parsed
while [ -n "${1:-}" ] ; do
  case "${1:-}" in
    --dialog) dialog="${2:-}" && shift ;;
    --display|--caption|--message) shift ;;
    --window) shift ;;
    --parent) pid="${2:-}" && shift ;;
    --) ;;
  esac
  shift
done
case $dialog in
  pulldown) ;;
  yesnosuspend)
    kill $pid
    echo timetosaygoodbye >> '$Timetosaygoodbyefile'
  ;;
esac
' >> "$NX_CLIENT"
      unpriv "chmod +x '$NX_CLIENT'"

      echo '<!DOCTYPE NXKeystroke>
    <keystrokes>
    <keystroke action="fullscreen" AltMeta="0" Control="0" Shift="1" key="F11" />
    <keystroke action="fullscreen" AltMeta="1" Control="1" Shift="1" key="f" />
</keystrokes>' >> "$NXAGENT_KEYSTROKEFILE"
    ;;

    --xwin)
      case $Sharegpu in
        no)
          Iglx="no"
          Xserveroptions="$Xserveroptions \\
  -nowgl" ;;
        yes) 
          Iglx="yes"
          Xserveroptions="$Xserveroptions \\
  -wgl" ;;
      esac
      
      case $Fullscreen in
        yes)
          Xserveroptions="$Xserveroptions \\
  -fullscreen" ;;
        no)
          Xserveroptions="$Xserveroptions \\
  -lesspointer"
          case $Desktopmode in
            yes)
              for ((Count=0 ; Count<$Outputcount ; Count++)); do 
                Xserveroptions="$Xserveroptions \\
  -screen $Count $Screensize"
              done
            ;;
            no) Xserveroptions="$Xserveroptions \\
  -multiwindow" ;;
          esac
        ;;
      esac
      
      case $Shareclipboard in
        yes) Xserveroptions="$Xserveroptions \\
  -clipboard" ;;
        no)  Xserveroptions="$Xserveroptions \\
  -noclipboard" ;;
      esac
      
      Xcommand="$(command -v XWin) :$Newdisplaynumber $Xserveroptions"
    ;;
    
    --runx)
      Xserveroptions="--display $Newdisplaynumber \
  --verbose"
      [ "$Xauthentication" = "no" ] && Xserveroptions="$Xserveroptions \
  --no-auth"
      [ "$Desktopmode" = "yes" ]    && Xserveroptions="$Xserveroptions \
  --desktop"
      [ "$Shareclipboard" = "yes" ] && Xserveroptions="$Xserveroptions \
  --clipboard"
      [ "$Screensize" ]             && Xserveroptions="$Xserveroptions \
  --size=$Screensize"
      [ "$Sharegpu" = "yes" ]       && { 
        Xserveroptions="$Xserveroptions \
  --gpu"
        store_runoption env "LIBGL_ALWAYS_INDIRECT=1"
      }
      Xcommand="$(command -v runx) $Xserveroptions"
    ;;

    --hostwayland|--hostdisplay|--tty) ;;
  esac
  
  case $Xserver in
    --tty|--hostdisplay|--runx) ;;
    --weston|--kwin|--hostwayland) ;;
    *)
      case "$Iglx" in
        yes) Xcommand="$Xcommand \\
  +iglx"
          store_runoption env "LIBGL_ALWAYS_INDIRECT=1" ;;
        no) 
          Xcommand="$Xcommand \\
      -iglx" ;;
      esac
    ;;
  esac
  
  # --xopt
  Xcommand="$Xcommand \\
  $Xserveroptions_custom"
  
  case $Xserver in
    --weston|--kwin|--hostwayland|--hostdisplay|--tty) Xcommand="" ;;
  esac
  case $Xserver in
    --weston|--kwin|--weston-xwayland|--kwin-xwayland|--xpra-xwayland|--xdummy-xwayland) ;;
    *) Compositorcommand="" ;;
  esac
  
  return 0
}