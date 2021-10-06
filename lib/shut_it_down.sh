shut_it_down() {
  log_daemon_msg \"Stopping \$DESC\" \"\$NAME\"
  start-stop-daemon --stop --retry 5 --quiet --oknodo --pidfile \$PIDFILE --user \$DAEMONUSER
  log_end_msg \$?
  rm -f \$PIDFILE
}