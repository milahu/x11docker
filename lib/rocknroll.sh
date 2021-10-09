rocknroll() {                   # check whether x11docker session is still running
  [ -s "$Timetosaygoodbyefile" ]   && return 1
  [ -e "$Timetosaygoodbyefile" ]   || return 1
  return 0
}