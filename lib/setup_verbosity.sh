setup_verbosity() {             # options --verbose, --stdout, --stderr
  local Line Logfiles
  # create summary logfile
  Logfiles="
    $Cmdstderrlogfile
    $Cmdstdoutlogfile
    $Compositorlogfile
    $Containerlogfile
    $Systemdjournallogfile
    $Messagelogfile
    $Xinitlogfile
    $Xpraclientlogfile
    $Xpraserverlogfile
    "
  for Line in $Logfiles; do
    [ -e "$Line" ] && grep -q "/" <<< "$Line" && Logfiles="$Logfiles $Line"
  done
  {
    trap '' SIGINT
    tail --pid="$$" --retry -n +1 -F $Logfiles 2>/dev/null >>$Logfile ||:
  } &

  # option --verbose
  [ "$Verbose" = "yes" ] && {
    trap '' SIGINT
    case $Verbosecolors in
      no)  tail --pid="$$" --retry -n +1 -F $Logfile 2>/dev/null >&${FDstderr} ;;
      yes) tail --pid="$$" --retry -n +1 -F $Logfile 2>/dev/null | sed "
                                      /\(Failed to add fd to store\|Failed to set invocation ID\|Failed to reset devices.list\)/d;
                                      s/\(ERROR\|Error\|error\|FAILURE\|FATAL\|Fatal\|fatal\)/${Colredbg}\1${Colnorm}/g;
                                      s/\(Failed\|failed\|Failure\|failure\)/${Colred}\1${Colnorm}/g;
                                      s/\(WARNING\|Warning\|warning\)/${Colyellow}\1${Colnorm}/g;
                                      s/\(DEBUGNOTE\)/${Colblue}\1${Colnorm}/g;
                                      s/^==>.*/${Coluline}\0${Colnorm}/;
                                      s/\(Starting\|Activating\)/${Colgreen}\0${Colnorm}/;
                                      s/\(Started\|Reached target\|activated\)/${Colgreenbg}\0${Colnorm}/;
                                      s/^\(+\|++\|+++\)/${Colgreenbg}\0${Colnorm}/ ;
                                      s/^x11docker/${Colgreen}\0${Colnorm}/ " >&${FDstderr}
      ;;
    esac
  } &
  
  [ "$Showcontaineroutput" = "yes" ]    && {
    {
      waitforlogentry tailstdout "$Storeinfofile" "x11docker=ready" ""  infinity ||:
      trap '' SIGINT
      tail --pid="$$" -n +1 -f $Cmdstdoutlogfile     2>/dev/null ||:
    } &
    {
      waitforlogentry tailstderr "$Storeinfofile" "x11docker=ready" ""  infinity ||:
      trap '' SIGINT
      tail --pid="$$" -n +1 -f $Cmdstderrlogfile >&2 2>/dev/null ||:
    } &
  }
    
  return 0
}