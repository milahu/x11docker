traperror() {                   # trap ERR: --debug: Output for 'set -o errtrace'
  debugnote "traperror: Command at Line ${2:-} returned with error code ${1:-}:
  ${4:-}
  ${3:-} - ${5:-}"
  storeinfo error=64
  saygoodbye traperror
}