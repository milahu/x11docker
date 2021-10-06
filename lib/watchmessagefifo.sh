watchmessagefifo() {            # watch for messages coming from container or dockerrc
  # message in fifo must end with :$Messagetype
  local Line= Message= Messagetype=
  trap '' SIGINT
  while [ -e "$Cachefolder" ]; do
    IFS= read -r Line <&${FDmessage} ||:
    [ "$Line" ] || sleep 2  # sleep for MSYS2/CYGWIN workaround
    [ "$Line" ] && Message="$Message
$Line"
    grep -q -E ":WARNING|:NOTE|:DEBUGNOTE|:VERBOSE|:ERROR|:STDOUT" <<< "$Line" && {
      Messagetype=":$(echo $Line | rev | cut -d: -f1  | rev)"
      Message="${Message%$Messagetype }"
      Message="$(tail -n +2 <<< "$Message")" # remove leading newline
      case "$Messagetype" in
        :WARNING)   warning   "$Message" ;;
        :NOTE)      note      "$Message" ;;
        :DEBUGNOTE) debugnote "$Message" ;;
        :ERROR)     error     "$Message" ;;
        :VERBOSE)   [ "-d " = "$(cut -c1-3 <<<"$Message" | head -n1)" ] && debugnote "$(tail -c +4 <<< "$Message")" || verbose "$Message" ;;
        :STDOUT)    echo "$Message" ;;
      esac
      Message=
      Messagetype=
    }
  done
}