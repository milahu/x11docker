pspid() {                       # ps -p $1 --no-headers
  # On some systems ps does not have option --no-headers.
  # On some systems (busybox) ps -p is not supported  ### FIXME
  # return 1 if not found
  LC_ALL=C ps -p "${1:-}" 2>/dev/null | grep -v 'TIME'
}