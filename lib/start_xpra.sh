start_xpra() {                  # options --xpra / --xpra-xwayland: start and watch xpra server and xpra client
  local Xpraserverpid Xpraclientpid Xpraenv
  
  Xpraenv="  NO_AT_BRIDGE=1 \\
  XPRA_EXPORT_ICON_DATA=0 \\
  XPRA_EXPORT_XDG_MENU_DATA=0 \\
  XPRA_ICON_OVERLAY=0 \\
  XPRA_MENU_ICONS=0 \\
  XPRA_UINPUT=0 \\
  XPRA_XDG_EXPORT_ICONS=0 \\
  XPRA_XDG_LOAD_GLOB=0 \\
  $(verlt $Xpraversion v2.1 && echo XPRA_OPENGL_DOUBLE_BUFFERED=1 ||:)"
  
  # xpra server
  Xpraservercommand="env XAUTHORITY=$Xclientcookie \\
  GDK_BACKEND=x11 \\
$Xpraenv $Xpraservercommand"
  debugnote "Running xpra server:
$Xpraservercommand"
  echo "x11docker [$(timestamp)]: Starting Xpra server" >> $Xpraserverlogfile
  unpriv "$Xpraservercommand ||:" >> $Xpraserverlogfile 2>&1 &
  Xpraserverpid=$!
  storepid $Xpraserverpid xpraserver
  
  verlt "$Xprarelease" "r23060" && waitforlogentry "xpra server" $Xpraserverlogfile 'xpra is ready' 
  rocknroll || return 64
  
  # xpra client
  Xpraclientcommand="env $Hostxenv \\
$Xpraenv $Xpraclientcommand"
  debugnote "Running xpra client:
$Xpraclientcommand"
  echo "x11docker [$(timestamp)]: Starting Xpra client" >> $Xpraclientlogfile
  unpriv "$Xpraclientcommand ||:" >> $Xpraclientlogfile 2>&1 & 
  Xpraclientpid=$!
  storepid $Xpraclientpid xpraclient

  # catch possible xpra crashes
  while rocknroll; do
    ps -p $Xpraserverpid >/dev/null || break
    ps -p $Xpraclientpid >/dev/null || break
    sleep 1
  done
  sleep 1 && rocknroll && note "Option $Xserver: xpra terminated unexpectedly.
  Last lines of xpra server log:
$(tail $Xpraserverlogfile)
---------------------------------
  Last lines of xpra client log:
$(tail $Xpraclientlogfile)"
  saygoodbye xpra
  
  return 0
}