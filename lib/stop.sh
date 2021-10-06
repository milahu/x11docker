stop() {
  ebegin \"Stopping D-BUS system messagebus\"
  start-stop-daemon --stop --pidfile /var/run/dbus.pid
  retval=\$?
  eend \${retval}
  [ -S /var/run/dbus/system_bus_socket ] && rm -f /var/run/dbus/system_bus_socket
  return \${retval}
}