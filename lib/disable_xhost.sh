disable_xhost() {               # remove any access to X server granted by xhost
  local Line=
  command -v xhost >/dev/null || {
    warning "Command 'xhost' not found.
  Can not check for possibly allowed network access to X.
  Please install 'xhost'."
    return 1
  }
  xhost 2>&1 | tail -n +2  /dev/stdin | while read -r Line ; do  # read all but the first line (header)
    debugnote "xhost: Removing entry $Line"
    xhost -$Line                                  # disable every entry
  done
  xhost -                                         # enable access control
  [ "$(xhost 2>&1 | wc -l)" -gt "1" ] && {
    warning "Remaining xhost permissions found on display ${DISPLAY:-}
$(xhost 2>&1 )"
    return 1
  }
  xhost 2>&1 | grep "access control disabled" && {
    warning "Failed to restrict xhost permissions.
  Access to display ${DISPLAY:-} is allowed for everyone." 
    return 1
  }
  return 0
}