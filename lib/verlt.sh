verlt() {                       # version number check $1 less than $2
  [ "${1:-}" = "${2:-}" ] && return 1 || { verlte "${1:-}" "${2:-}" && return 0 || return 1 ; }
}