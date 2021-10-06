logentry() {                    # write into logfile
  [ -e "$Logfile" ] && {
    [ -n "$Logmessages" ] && echo "$Logmessages" >>$Messagelogfile 2>/dev/null && Logmessages=""
    echo "$*" >>$Messagelogfile 2>/dev/null 
    :
  } || Logmessages="$Logmessages
$*" 
}