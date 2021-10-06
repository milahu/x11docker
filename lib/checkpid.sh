checkpid() {                    # check if PID $1 is active
  #ps -p ${1:-} >/dev/null 2>&1
  [ -e "/proc/${1:-NONSENSE}" ]
}