debugnote() {                   # show debug output $*
  [ "$Debugmode" = "yes" ] && [ "$Verbose" = "no" ] && echo "${Colblue}DEBUGNOTE[$(timestamp)]:${Colnorm} $*" >&${FDstderr}
  logentry "DEBUGNOTE[$(timestamp)]: $*"
  return 0
}