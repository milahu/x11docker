finish() {                      # trap EXIT routine to clean up background processes and cache
  local Pid Name Zeit Exitcode Pid1pid= Dockerlogspid= Dockerstopshellpid= Wmcontainerpid1= Watchmessagefifopid= i 

  # do not finish() in subshell, just give signal to all other processes and terminate subshell
  [ "$$" = "$BASHPID" ] || {
    saygoodbye finish-subshell
    exit 0
  }

  debugnote "Terminating x11docker."
  saygoodbye "finish"
  trap - EXIT
  trap - ERR
  trap - SIGINT
  
  # --pw=sudo: no password prompt here, rather fail ### FIXME
  [ "$Sudo" ] && {
    sudo -n echo 2>/dev/null && Sudo="sudo -n" || Sudo=""
  }

  while read -r Line ; do
    
    Pid="$(echo $Line  | awk '{print $1}')"
    Name="$(echo $Line | awk '{print $2}')"
    debugnote "finish(): Checking pid $Pid ($Name): $(pspid $Pid || echo '(already gone)')"
      
    checkpid $Pid && {
      case $Name in
        watchmessagefifo)
          Watchmessagefifopid="$Pid"
        ;;
        dockerstopshell)
          Dockerstopshellpid="$Pid"
        ;;
        dockerlogs)
          Dockerlogspid=$Pid
          #[ "$Winsubsystem" ] && Dockerlogspid=""
        ;;
        containerpid1)
          Pid1pid="$Pid"
          #[ "$Winsubsystem" ] && Pid1pid=""
          termpid "$Pid1pid" "$Name" || Debugmode="yes"
          # Give container time for graceful shutdown
          for Count in 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0; do
            checkpid $Pid1pid || break
            mysleep $(awk "BEGIN { print $Count * 0.1 }")
            debugnote "finish(): Waiting for container PID 1: $Pid1pid to terminate."
          done
        ;;
        wmcontainerpid1)
          Wmcontainerpid1="$Pid"
          #[ "$Winsubsystem" ] && Wmcontainerpid1=""
          termpid "$Wmcontainerpid1" "$Name" 
        ;;
        *) 
          termpid "$Pid" "$Name" 
        ;;
      esac
    }
  done < <(tac "$Storepidfile" 2>/dev/null)

  # --pulseaudio: unload module
  Pulseaudiomoduleid="$(storeinfo dump pulseaudiomoduleid)"
  [ "$Pulseaudiomoduleid" ] && pactl unload-module "$Pulseaudiomoduleid" 

  # Check if container is still running -> docker stop
  [ "$X11dockermode" = "run" ] && containerisrunning && {
    Debugmode="yes"
    debugnote "finish(): Container still running. Executing 'docker stop'.
  Will wait up to 15 seconds for docker to finish."
  
    case $Mobyvm in
      no)  echo "stop" >> "$Dockerstopsignalfifo" ;;
      yes) $Containerbackendbin stop $Containername >>$Containerlogfile 2>&1 ;;
    esac
    
    Zeit="$(date +%s)"
    while :; do
      containerisrunning || break
      debugnote "finish(): Waiting for container to terminate ..."
      sleep 1
      [ 15 -lt $(($(date +%s) - $Zeit)) ] && break
    done
      
    containerisrunning && {
      Exitcode="64"
      debugnote "finish(): Container did not terminate as it should.
  Will not clean cache to avoid file permission issues.
  You can remove the new container with command:
    docker rm -f $Containername
  Afterwards, remove cache files with:
    rm -R $Cachefolder
  or let x11docker do the cleanup work for you:
    x11docker --cleanup"
      Preservecachefiles="yes"
    } || debugnote "finish(): Container terminated successfully"
  }
  
  # remove container
  [ "$Preservecachefiles" = "no" ] && [ "$Containername" ] && {
    debugnote "Removing container $Containername
    $($Containerbackendbin rm -f "$Containername" 2>&1)"
  }

  # Check if 'docker logs' is still running
  [ "$FDdockerstop" ] && {
    checkpid $Dockerlogspid      && echo "stop" >&${FDdockerstop}
    # Check if window manager container is still running
    checkpid $Wmcontainerpid1    && echo "stop" >&${FDdockerstop}
    # Terminate watching subshell in dockerrc
    [ -e "$Dockerstopsignalfifo" ] && echo "exit" >&${FDdockerstop}
    checkpid $Dockerstopshellpid && sleep 1
  }
  
  # Stop watching for messages, check others again
  while read -r Line ; do
    Pid="$(echo $Line  | awk '{print $1}')"
    Name="$(echo $Line | awk '{print $2}')"
    checkpid $Pid && termpid "$Pid" "$Name"
    checkpid $Pid && {
      # should never happen
      warning "Failed to terminate pid $Pid ($Name): $(pspid $Pid ||:)"
      storeinfo error=64
    }
  done < <(tac "$Storepidfile" 2>/dev/null)

  Exitcode=$(storeinfo dump error)
  Exitcode="${Exitcode:-0}"
  debugnote "x11docker exit code: $Exitcode"
  storeinfo test cmdexitcode && {
    Exitcode=$(storeinfo dump cmdexitcode)
    debugnote "CMD exit code: $Exitcode"
  }
  
  # backup of logfile in $Cachebasefolder
  [ -e "$Logfile" ] && {
    [ "$Verbose" = "yes" ] && sleep 1
    unpriv "cp '$Logfile' '$Logfilebackup'"
    case $Winsubsystem in
      WSL1|WSL2)
        [ "$Mobyvm" = "yes" ] && unpriv "cp -T '$Logfilebackup' '$Hostuserhome/.cache/x11docker/x11docker.log'"
      ;;
    esac
    #unpriv "rmcr '$Logfilebackup'"
  }

  # close file descriptors
  mysleep 0.2
  for Descriptor in ${FDcmdstdin} ${FDdockerstop} ${FDmessage} ${FDstderr} ${FDtimetosaygoodbye} ${FDwatchpid} ; do
    exec {Descriptor}>&-
  done
  
  # remove cache files
  [ "$Preservecachefiles" = "no" ] && grep -q cache <<<$Cachefolder && grep -q x11docker <<<$Cachefolder && [ "x11docker" != "$(basename "$Cachefolder")" ] && unpriv "rm -f -R '$Cachefolder'"
  
  case $Runssourced in
    yes) return $Exitcode ;;
    *)   exit   $Exitcode ;;
  esac
}