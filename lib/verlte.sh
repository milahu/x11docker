verlte() {                      # version number check $1 less than or equal $2
  [  "${1:-}" = "$(echo -e "${1:-}\n${2:-}" | sort -V | head -n1)" ] && return 0 || return 1
}