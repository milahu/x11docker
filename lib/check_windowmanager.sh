check_windowmanager() {         # option --wm: search a host window manager
  # check --wm arguments, adjust mode
  case "$Windowmanagermode" in
    ""|none)
      Windowmanagermode="none"
      return 0
    ;;
    auto)
      Windowmanagermode="host"
      [ -n "$Windowmanagercommand" ] && {
        command -v "$(cut -d' ' -f1 <<< "$Windowmanagercommand")" >/dev/null && {
          Windowmanagermode="host"
        } || {
          note "Option --wm: Did not find command on host: $Windowmanagercommand"
          check_fallback
        }
      }
    ;;
    host) ;;
  esac
    
  # Find a host window manager
  [ "$Windowmanagercommand" ] || for Windowmanagercommand in $Wm_all WM_NOT_FOUND; do
    command -v "$Windowmanagercommand" >/dev/null && break
  done
  
  [ "$Windowmanagercommand" = "WM_NOT_FOUND" ] && {
    Windowmanagercommand=""  
    note "Option --wm: No host window manager found.
    Please install a supported one. Recommended:
  $Wm_recommended_nodesktop_light
  Fallback: Setting --wm=none"
    check_fallback
    Windowmanagermode="none"
  }
  
  [ "$Windowmanagermode" = "none" ] && return 0
  
  [ "$Xtest" = "yes" ] && warning "Options --xtest --wm: Did not disable X extension XTEST
  for X server $Xserver.
  If your host window manager '$Windowmanagercommand' can start applications
  on its own (for example with a context menu), container applications
  can abuse this to run and remotely control host applications.
  If you provide content of X server $Xserver over network to others,
  they may take control over your host system!"
  
  # command adjustment for some host window managers
  case $(basename "$(cut -d' ' -f1 <<< "$Windowmanagercommand")") in
    cinnamon|cinnamon-session) Windowmanagercommand="cinnamon --sm-disable";;
    compiz) # if none, create minimal config to have usable window decoration and can move windows
      [ -e "$Hostuserhome/.config/compiz-1/compizconfig/Default.ini" ] || {
        unpriv "mkdir -p '$Hostuserhome/.config/compiz-1/compizconfig'"
        mkfile "$Hostuserhome/.config/compiz-1/compizconfig/Default.ini"
        echo '[core]
s0_active_plugins = core;composite;opengl;decor;resize;move;
' >> "$Hostuserhome/.config/compiz-1/compizconfig/Default.ini"
      }  ;;
    enlightenment|e17|e16|e19|e20|e) Windowmanagercommand="enlightenment_start" ;;
    matchbox) Windowmanagercommand="matchbox-window-manager"  ;;
    mate|mate-session) Windowmanagercommand="mate-session -f" ;;
    mate-wm) Windowmanagercommand="marco --sm-disable"  ;;
    openbox) 
      Windowmanagercommand="openbox --sm-disable" 
      [ -e "/etc/xdg/openbox/rc.xml" ] && {
        cp /etc/xdg/openbox/rc.xml $Sharefolder/openbox-nomenu.rc
        sed -i /ShowMenu/d         $Sharefolder/openbox-nomenu.rc
        sed -i s/NLIMC/NLMC/       $Sharefolder/openbox-nomenu.rc
        Windowmanagercommand="$Windowmanagercommand --config-file $Sharefolder/openbox-nomenu.rc"
      }
    ;;
  esac
  
  verbose "Detected host window manager: ${Windowmanagercommand:-"(none)"}"
  set +x
  return 0
}