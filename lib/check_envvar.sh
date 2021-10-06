check_envvar() {                # allow only chars in string $1 that can be expected in environment variables
  # Allows only chars in "a-zA-Z0-9_:/.,@=-"
  # Option -w allows whitespace, too. Can be needed for PATH.
  # Char * as in LS_COLORS is not allowed to avoid abuse.
  # Replaces forbidden chars with X and returns 1
  # Returns 0 if no change occurred.
  # Echoes result.
  local Newvar Space=
  
  case "${1:-}" in
    -w) Space=" " ; shift ;;
  esac
  
  Newvar="$(printf %s "${1:-}" | LC_ALL=C tr -c "a-zA-Z0-9_:/.,@=${Space}-" "X" )"
  
  printf %s "$Newvar"
  printf "\n"
  
  [ "$Newvar" = "${1:-}" ] && return 0
  
  debugnote "check_envvar(): Input string has been changed. Result:
  $Newvar"
  return 1
}