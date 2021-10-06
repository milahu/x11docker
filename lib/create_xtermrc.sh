create_xtermrc() {              # create xtermrc: Script to prompt for password (if needed) and to run dockerrc
  echo "#! /usr/bin/env bash"
  echo "# Ask for password if needed."
  echo "# Runs in terminal or in an additional terminal window"
  echo ""
  declare -f rocknroll
  declare -f storeinfo
  echo "$Messagefifofuncs"
  echo "Timetosaygoodbyefile='$Timetosaygoodbyefile'"
  echo ""
  #[ "$Debugmode" = "yes" ] && echo "set -x"
  echo "Messagefile='$Messagefifo'"
  echo "Storeinfofile='$Storeinfofile'"
  echo "export TERM=xterm SHELL=/bin/bash"
  echo ""  
  echo "debugnote 'Running xtermrc: Ask for password if needed ($Passwordneeded)'"
  echo ""
  [ "$Passwordneeded" = "yes" ] && case $Passwordfrontend in
    su|sudo)
      echo "echo 'x11docker $Imagename $Containercommand:'"
      echo "echo 'Please type in your password to run docker on display $Newdisplay'"
      echo "echo -n 'Password ($Passwordfrontend): '"
    ;;
  esac
  echo ""
  case $Passwordfrontend in
    gksudo|lxsudo)  echo "$Passwordcommand bash $Dockerrc" ;;
    pkexec)         echo "pkexec env DISPLAY=\$DISPLAY XAUTHORITY=\$XAUTHORITY bash $Dockerrc" ;;
    gksu)           echo "$Passwordcommand \"bash $Dockerrc \"" ;;
    lxsu)           echo "$Passwordcommand bash $Dockerrc" ;;
    *)              echo "$Passwordcommand \"${Sudo}bash $Dockerrc \"" ;;
  esac
  echo ""
  echo "storeinfo xtermrc=ready"  
  echo "exit 0"
  return 0
}