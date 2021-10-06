storepid() {                    # store pid $1 and name $2 of process in file $Storepidfile.
  # Store pid and process name of background processes in a file
  # Used in finish() to clean up background processes
  # Store:
  #  $1 Pid
  #  $2 codename
  # Test for stored pid or codename:
  #  $1 test
  #  $2 pid or codename
  # Dump stored pid:
  #  $1 dump
  #  $2 codename
  
  case "${1:-}" in
    dump) grep    -w "${2:-}" "$Storepidfile" | cut -d' ' -f1 ;;
    test) grep -q -w "${2:-}" "$Storepidfile" ;;
    *)
      echo "${1:-NOPID}" "${2:-NONAME}" >> "$Storepidfile"
      debugnote "storepid(): Stored pid '${1:-}' of '${2:-}': $(pspid ${1:-} ||:)"
    ;;
  esac
}