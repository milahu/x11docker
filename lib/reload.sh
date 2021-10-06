reload() {
  ebegin \"Reloading D-BUS messagebus config\"
  /usr/bin/dbus-send --print-reply --system --type=method_call --dest=org.freedesktop.DBus / org.freedesktop.DBus.ReloadConfig > /dev/null
  retval=\$?
  eend \${retval}
  return \${retval}
}