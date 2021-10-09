waitforlogentry() {             # wait for entry $3 in logfile $2 of application $1
  # $1 is the application we are waiting for to be ready
  # $2 points to logfile
  # $3 keyword to wait for
  # $4 possible error keywords
  # $5 time to wait in seconds or infinity. default: 60

  local Startzeit Uhrzeit Dauer Count=0 Schlaf
  local Errorkeys="${4:-}"
  local Warten="${5:-60}"
  local Error=
  
  Startzeit="$(date +%s ||:)"
  Startzeit="${Startzeit:-0}"
  [ "$Warten" = "infinity" ] && Warten=32000

  debugnote "waitforlogentry(): ${1:-}: Waiting for logentry \"${3:-}\" in $(basename ${2:-})"
  
  while ! grep -q "${3:-}" <"${2:-}" ; do
    Count="$(( $Count + 1 ))"
    Uhrzeit="$(date +%s ||:)"
    Uhrzeit="${Uhrzeit:-0}"
    Dauer="$(( $Uhrzeit - $Startzeit ))"
    Schlaf="$(( $Count / 10 ))"
    [ "$Schlaf" = "0" ] && Schlaf="0.5"
    mysleep "$Schlaf"
    
    [ "$Dauer" -gt "10" ] && debugnote "waitforlogentry(): ${1:-}: Waiting since ${Dauer}s for log entry \"${3:-}\" in $(basename ${2:-})"
    
    [ "$Dauer" -gt "$Warten" ] && error "waitforlogentry(): ${1:-}: Timeout waiting for entry \"${3:-}\" in $(basename ${2:-})
  Last lines of $(basename ${2:-}):
$(tail "${2:-}")"
    
#    grep -i -q -E 'xinit: giving up|unable to connect to X server|Connection refused|server error|Only console users are allowed|Failed to process Wayland|failed to create display|] fatal:' <"${2:-}" && \
    [ "$Errorkeys" ] && grep -i -q -E "$Errorkeys" <"${2:-}" && \
      error "waitforlogentry(): ${1:-}: Found error message in logfile.
  Last lines of logfile $(basename ${2:-}):
$(tail "${2:-}")"

    rocknroll || {
      debugnote "waitforlogentry(): ${1:-}: Stopped waiting for ${3:-} in $(basename ${2:-}) due to terminating signal."
      Error=1
      break
    }
  done
  [ "$Error" ] && return 1

  debugnote "waitforlogentry(): ${1:-}: Found log entry \"${3:-}\" in $(basename ${2:-})."
  return 0
}