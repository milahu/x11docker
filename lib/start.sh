start() {
  ebegin \"Starting D-BUS system messagebus\"
  /usr/bin/dbus-uuidgen --ensure=/etc/machine-id
  mkdir -p /var/run/dbus 
  start-stop-daemon --start --pidfile /var/run/dbus.pid --exec /usr/bin/dbus-daemon -- --system
  eend \$?
}