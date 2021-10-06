setonwatchpidlist() {           # add PID $1 to watchpidlist()
  debugnote "watchpidlist(): Setting pid ${1:-} on watchlist: ${2:-}"
  echo "${1:-}" >>$Watchpidfifo
  # add to list of background processes
  grep -q CONTAINER <<<  "${1:-}" || storepid "${1:-}" "${2:-}"
}