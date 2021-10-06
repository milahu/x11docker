setup_hostdbus() {              # option --hostdbus: connect to host DBus session daemon.
  warning "--hostdbus: Connecting container to host DBus degrades
  container isolation. Container applications might send malicious requests."
  Dbusrunsession=no
    
  [ "$DBUS_SESSION_BUS_ADDRESS" ] || {
    # no running DBus session?
    command -v dbus-launch >/dev/null && {
      export $(dbus-launch)
      note "Option --hostdbus: DBUS_SESSION_BUS_ADDRESS is empty.
  Creating abstract DBus socket with dbus-launch."
    } || note "Option --hostdbus: Is DBus running on host?
  Did not find an active session and did not find dbus-launch.
  DBUS_SESSION_BUS_ADDRESS is empty.
  $Wikipackages"
  }
    
  grep -q "unix:path" <<< "$DBUS_SESSION_BUS_ADDRESS" && {
    # DBus socket file
    store_runoption env "DBUS_SESSION_BUS_ADDRESS=$DBUS_SESSION_BUS_ADDRESS"
    store_runoption volume "/$(cut -d/ -f2- <<<"$DBUS_SESSION_BUS_ADDRESS"):ro"
  }
    
  grep -q "unix:abstract" <<< "$DBUS_SESSION_BUS_ADDRESS" && {
    # DBus abstract socket (dbus-launch)
    store_runoption env "DBUS_SESSION_BUS_ADDRESS=$DBUS_SESSION_BUS_ADDRESS"
    [ "${DBUS_SESSION_BUS_PID:-}" ]      && store_runoption env  "${DBUS_SESSION_BUS_PID:-}"
    [ "${DBUS_SESSION_BUS_WINDOWID:-}" ] && store_runoption env  "${DBUS_SESSION_BUS_WINDOWID:-}"
    Network="host"
    warning "Option --hostdbus: Did not find a DBus session socket file
  but an abstract unix socket. To allow access for container,
  x11docker sets option '--network=host'.
  This degrades container isolation. Container shares host network stack."
  }
  return 0
}