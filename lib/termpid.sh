termpid() {                     # kill PID $1 with codename $2
  # TERM
  debugnote "termpid(): Terminating ${1:-} (${2:-}): $(pspid ${1:-} ||:)"
  checkpid "${1:-}" && {
    kill         ${1:-} 2>/dev/null
    :
  } || return 0
  mysleep 0.1
  checkpid "${1:-}" && mysleep 0.4 || return 0
  
  # KILL
  debugnote "termpid(): Killing ${1:-} (${2:-}): $(pspid ${1:-} ||:)"
  checkpid "${1:-}" && kill -s KILL ${1:-} 2>/dev/null
  mysleep 0.2 
  checkpid "${1:-}" && {
    note "Failed to terminate ${1:-} (${2:-}): $(ps -u -p ${1:-} 2>/dev/null | tail -n1)"
    return 1
  }
  
  return 0
}