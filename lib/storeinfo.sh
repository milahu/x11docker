storeinfo() {                   # store some information for later use
  # store and provide pieces of information
  # replace entry if codeword is already present
  # Store as codeword=string:
  #   $1 codeword=string
  # Dump stored string:
  #   $1 dump
  #   #2 codeword
  # Drop stored string:
  #   $1 drop
  #   #2 codeword
  # Test for codeword: (return 1 if not found)
  #   $1 test
  #   $2 codeword
  #
  # note: sed -i causes file permission issues if called in container in Cygwin, compare ticket #187
  #       chmod 666 for $Sharefolder could probably fix that. (FIXME)
  #
  [ -e "$Storeinfofile" ] || return 1
  case "${1:-}" in
    dump) grep     "^${2:-}="   $Storeinfofile | sed "s/^${2:-}=//" ;;      # dump entry
    drop) sed -i  "/^${2:-}=/d" $Storeinfofile ;;                           # drop entry
    test) grep -q  "^${2:-}="   $Storeinfofile ;;                           # test for entry
    *)                                                                      # store entry
      debugnote "storeinfo(): ${1:-}"
      grep -q   "^$(echo "${1:-}" | cut -d= -f1)="     $Storeinfofile && {
        sed -i "/^$(echo "${1:-}" | cut -d= -f1)=/d"   $Storeinfofile       # drop possible old entry
      }
      echo "${1:-}"                                 >> $Storeinfofile
    ;;
  esac
}