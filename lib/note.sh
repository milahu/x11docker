note() {                        # show notice messages
  [ "$Verbose" = "no" ] && echo "${Colgreen}x11docker note:${Colnorm} $*
" >&${FDstderr}
  logentry "x11docker note: $*
"
}