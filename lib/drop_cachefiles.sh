drop_cachefiles() {             # remove some cache files that are not needed in current setup
  case $Initsystem in
    systemd) ;;
    *) rm $Systemdconsoleservice $Systemdenvironment $Systemdjournallogfile $Systemdjournalservice $Systemdtarget $Systemdwatchservice ;;
  esac
  case $Xserver in
    --xpra|--xpra-xwayland) ;;
    *) rm $Xpraclientlogfile $Xpraserverlogfile ;;
  esac
  case $Xserver in
    --weston|--weston-xwayland|--kwin|--kwin-xwayland|--xpra-xwayland|--xdummy-xwayland) ;;
    *) rm $Compositorlogfile $Westonini ;;
  esac
  case $Xserver in
    --weston|--kwin|--hostwayland|--tty) rm $Xclientcookie $Xservercookie ;;
    *) [ "$Xauthentication" = "no" ]  && rm $Xclientcookie $Xservercookie ;;
  esac
  case $Xserver in
    --nxagent) ;;
    *) rm $Nxagentclientrc $Nxagentkeysfile $Nxagentoptionsfile ;;
  esac
  case $Xserver in
    --xdummy) ;;
    --xpra) [ "$Xpravfb" = "Xdummy" ] || rm $Xdummyconf $Xorgwrapper ;;
    *) rm $Xdummyconf $Xorgwrapper ;;
  esac
  case $X11dockermode in
    exe) rm $Containerrootrc $Dockercommandfile $Dockerinfofile $Dockerrc ;;
  esac
  case $Xserver in
    --xephyr|--xorg|--xdummy|--xdummy-xwayland|--xvfb|--xwayland|--weston-xwayland) 
      [ "$Shareclipboard" = "no" ] && rm $Clipboardrc ;;
    *)                                rm $Clipboardrc ;;
  esac
  case $Xserver in
    --hostdisplay|--xwin|--nxagent|--hostwayland|--weston|--kwin|--tty) rm $Xkbkeymapfile ;;
  esac
}