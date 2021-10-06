unpriv() {                      # run a command as unprivileged user. Needed if x11docker was started by root or with sudo.
  # $Unpriv is declared in check_hostuser: 'eval' or 'su $Hostuser -c'
  $Unpriv "${1:-}"
}