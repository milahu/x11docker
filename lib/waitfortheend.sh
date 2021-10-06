waitfortheend() {               # wait for end of x11docker session
  # signal is byte in $Timetosaygoodbyefifo
  # decent read to wait for signal to terminate
  case $Usemkfifo in
    yes)
      while rocknroll; do
        bash -c "read -n1 <${FDtimetosaygoodbye}" && saygoodbye timetosaygoodbyefifo || sleep 1
      done
    ;;
    no) # Reading from fifo fails on Windows, workaround
      while rocknroll; do
        sleep 2
      done
    ;;
  esac
  return 0
}