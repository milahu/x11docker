saygoodbye() {                  # create file signaling watching processes to terminate
  debugnote "time to say goodbye ($*)"
  [ -e "$Timetosaygoodbyefile" ] && echo timetosaygoodbye >> $Timetosaygoodbyefile
  [ -e "$Timetosaygoodbyefifo" ] && echo timetosaygoodbye >> $Timetosaygoodbyefifo
}