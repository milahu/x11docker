watchpidlist() {                # watch list of important pids
  # terminate x11docker if a PID in $Watchpidlist terminates
  # serves mainly watching X server, Wayland compositor, container and hostexe
  # echo PIDs to watch into >{FDwatchpid} (setonwatchpidlist())
  local Pid= Containername= Line= Watchpidlist=
  trap '' SIGINT
  
  while rocknroll; do
    # check for new Pid once a second
    read -t1 Pid <&${FDwatchpid} ||:
    [ "$Usemkfifo" = "no" ] && sleep 2  # read does not wait if not a fifo
    # Got new pid
    [ "$Pid" ] && {
      [ "${Pid:0:9}" = "CONTAINER" ] && {
        # Workaround for MS Windows where the pid cannot be watched
        Containername="${Pid#CONTAINER}"
        debugnote "watchpidlist(): Watching Container: $Containername"
      } || {
        Watchpidlist="$Watchpidlist $Pid"
        debugnote "watchpidlist(): Watching pids: 
$(for Line in $Watchpidlist; do pspid "$Line" || echo "(pid $Line not found)" ; done)"
      }
    }
    # check all stored pids
    for Pid in $Watchpidlist; do
      [ -e /proc/$Pid ] || {
        debugnote  "watchpidlist(): PID $Pid has terminated"
        saygoodbye "watchpidlist $Pid"
      }
    done
    # Container PID not watchable in MSYS2/Cygwin/WSL11.
    [ "$Containername" ] && {
      $Containerbackendbin inspect $Containername >/dev/null || {
        debugnote "watchpidlist(): Container $Containername has terminated"
        saygoodbye "watchpidlist $Containername"
      }
    }
  done
  saygoodbye "watchpidlist"
}