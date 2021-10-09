check_xpraoption() {            # check if xpra option $1 is available
  local Option
  Option="$(cut -d= -f1 <<< "${1:-}")"
  grep -q "noprobe" <<< "${1:-}" && {
    grep "OpenGL" <<< "$Xprahelp" | grep -q "probe" && echo "$@" || {
      debugnote "Xpra option $@ not supported: $Option"
      return 1
    }
    return 0
  }
  grep -q -- "$Option" <<< "$Xprahelp" && echo "$@" || {
    debugnote "Xpra option not found: $Option"
    return 1
  }
}