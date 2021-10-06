setup_fifo() {                  # set up fifo channels (also option --stdin)
  # setup fifos to allow messages from within container, dockerrc and xinitrc
  # and to send pids to watch to watchpidlist() thread

  # file descriptors in use:
  # FDstderr            stderr                for warnings and notes redirected to &2, with --silent redirected to /dev/null
  # FDmessage           $Messagefifo          for messages from other threads to watchmessagefifo()
  # FDcmdstdin          stdin>>$Cmdstinfile   --stdin with catstdin, redirection of &0
  # FDtimetosaygoodbye  $Timetosaygoodbyefifo for saygoodbye() and waitfortheend()
  # FDwatchpid          $Watchpidfifo         for watchpidlist()
  # FDdockerstop        $Dockerstopsignalfifo to send docker stop signal to dockerrc in finish()

  case "$Mobyvm" in
    yes) Usemkfifo="no" ;;
    no)  Usemkfifo="yes" ;;
  esac
  [ "$Runtime" = "kata-runtime" ] && Usemkfifo="no"
  
  # redirect stdin to named pipe. Named pipe is shared with container and used as stdin of container command in containerrc
  [ "$Forwardstdin" = "yes" ] && {
    case $Usemkfifo in
      yes) unpriv "mkfifo $Cmdstdinfifo" ;;
      no)  mkfile $Cmdstdinfifo ;;
    esac
    exec {FDcmdstdin}<>$Cmdstdinfifo 
    cat <&0 >${FDcmdstdin} & storepid $! catstdin
    storeinfo "stdin=$Cmdstdinfifo"
  }

  case $Usemkfifo in
    yes)
      unpriv "mkfifo $Watchpidfifo"
      unpriv "mkfifo $Messagefifo && chmod 666 $Messagefifo"
      unpriv "mkfifo $Timetosaygoodbyefifo"
    ;;
    no) # Windows, kata
      mkfile $Watchpidfifo
      mkfile $Messagefifo 666
      mkfile $Timetosaygoodbyefifo 666
    ;;
  esac
  
  case $Mobyvm in
    no)
      # used by finish() and dockerrc
      unpriv "mkfifo $Dockerstopsignalfifo"
      exec {FDdockerstop}<>$Dockerstopsignalfifo
    ;;
  esac
  
  # used by waitfortheend()
  exec {FDtimetosaygoodbye}<>$Timetosaygoodbyefifo
  
  # start watching important pids, e.g. xinit, container.
  exec {FDwatchpid}<>$Watchpidfifo
  watchpidlist & storepid $! watchpidlist
  
  # start watching for messages out of container or dockerrc
  exec {FDmessage}<>$Messagefifo
  watchmessagefifo & storepid $! watchmessagefifo
  
  return 0
}