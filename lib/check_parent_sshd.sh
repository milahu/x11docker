check_parent_sshd() {           # check whether pid $1 runs in SSH session
  local Wanted_pid="${1:-}" Process_line
  local Return
  ps -p 1 >/dev/null 2>&1 || {
    debugnote "check_parent_sshd(): Failed to check for sshd. ps -p not supported."
    return 1
  }
  while [ $Wanted_pid -ne 1 ] ; do
    Process_line="$(ps -f -p "$Wanted_pid"| tail -n1)"
    Wanted_pid="$(echo $Process_line| awk '{print $3}')"
    [[ $Process_line =~ sshd ]] && Return=0
    [ "$Return" ] && break
  done
  return ${Return:-1}
}