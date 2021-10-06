start_it_up() {
  [ -d \$PIDDIR ] || {
    mkdir -p \$PIDDIR
    chown \$DAEMONUSER \$PIDDIR
    chgrp \$DAEMONUSER \$PIDDIR
  }
  mountpoint -q /proc/ || {
    log_failure_msg \"Cannot start \$DESC - /proc is not mounted\"
    return 1
  }
  [ -e \$PIDFILE ] && {
    \$0 status > /dev/null && {
      log_success_msg \"\$DESC already started; not starting.\"
      return 0
    }
    log_success_msg \"Removing stale PID file \$PIDFILE.\"
    rm -f \$PIDFILE
  }
  create_machineid
  log_daemon_msg \"Starting \$DESC\" \"\$NAME\"
  start-stop-daemon --start --quiet --pidfile \$PIDFILE --exec \$DAEMON -- --system \$PARAMS
  log_end_msg \$?
}