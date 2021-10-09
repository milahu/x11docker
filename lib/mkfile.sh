mkfile() {                      # create file $1 owned by $Hostuser
  :> "${1:-}"                 || return 1
  chown $Hostuser    "${1:-}" || return 1
  chgrp $Hostusergid "${1:-}" || return 1
  chmod 644          "${1:-}" || return 1
  [ -n "${2:-}" ] && { chmod ${2:-} "${1:-}" || return 1 ; }
  return 0
}