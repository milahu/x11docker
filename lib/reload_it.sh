reload_it() {
  create_machineid
  log_action_begin_msg \"Reloading \$DESC config\"
  dbus-send --print-reply --system --type=method_call --dest=org.freedesktop.DBus / org.freedesktop.DBus.ReloadConfig > /dev/null
  log_action_end_msg \$?
}