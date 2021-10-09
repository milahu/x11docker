warning() {                     # show warning messages
  [ "$Verbose" = "no" ] && echo "${Colyellow}x11docker WARNING:${Colnorm} $*
" >&${FDstderr}
  logentry "x11docker WARNING: $*
"
}