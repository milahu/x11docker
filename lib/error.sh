error() {                       # show error message and exit
  local Message

  Message="$*

  Type 'x11docker --help' for usage information
  Debug options: '--verbose' (full log) or '--debug' (log excerpt).
  Logfile will be: $Logfilebackup
  Please report issues at https://github.com/mviereck/x11docker"
  
  Message="$(rmcr <<< "$Message")"

  # output to terminal
  [ "$Verbose" = "no" ] && echo -e "
${Colredbg}x11docker ERROR:${Colnorm} $Message
" >&2

  # output to logfile
  logentry "x11docker ERROR: $Message
"
  saygoodbye error
  storeinfo test error && waitfortheend
  storeinfo error=64

  # output to X dialogbox if not running in terminal
  [ "$Runsinterminal" = "no" ] && [ "$Silent" = "no" ] && export ${Hostxenv:-DISPLAY} && alertbox "x11docker ERROR" "$Message" &
  
  finish
}