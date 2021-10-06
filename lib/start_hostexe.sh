start_hostexe() {               # options --exe, --xonly: Run host executable instead of docker container
  local Line
  
  # generate start script
  { echo "#! /usr/bin/env bash"
    echo "# --exe: Run host executable $Hostexe"
    echo ""
    #[ "$Debugmode" = "yes" ] && echo "set -Eux"
    echo "$Messagefifofuncs"
    declare -f pspid
    declare -f storeinfo
    declare -f storepid
    echo ""
    echo "Messagefile='$Messagefifo'"
    echo "Storeinfofile='$Storeinfofile'"
    echo "Storepidfile='$Storepidfile'"
    echo "Tini=''"
    [ "$Dbusrunsession" = "yes" ] && echo "Dbus='$(command -v dbus-run-session >/dev/null)'"
    
    echo "export $Newxenv"
    [ "$Setupwayland" = "no" ] && {
      echo "unset WAYLAND_DISPLAY"
      echo "unset $Waylandtoolkitvars"
    }
    echo ""
    case $Xserver in
      --weston|--kwin|--hostwayland)
        echo "unset DISPLAY XAUTHORITY"
      ;;
    esac
    
    echo "export HOME='$Containeruserhome'"
    echo "cd '$Containeruserhome'"

    [ "$Workdir" ] && echo "cd '$Workdir'"
    echo ""
    
    while read Line; do
      echo "export '$Line'"
    done < <(store_runoption dump env | grep -v XAUTHORITY | grep -v XDG_RUNTIME_DIR)
    echo ""
    
    echo "env >> $Containerenvironmentfile"
    echo "verbose \"Container environment:"
    echo "\$(env | sort)\""
    echo ""
    
    [ "$Windowmanagermode" = "host" ] && echo "  ${Windowmanagercommand:-NO_WM_FOUND} >>$Xinitlogfile 2>&1 & storepid \$! windowmanager"
    echo ""
    
    echo "storeinfo test tini && {"
    echo "  Tini=\"\$(storeinfo dump tini)  --\" "
    echo "  export TINI_SUBREAPER=1"
    echo "}"
    echo ""
    
    echo "# close additional file descriptors"
    echo "for i in 3 4 6 7 8 9; do"
    echo "  { >&\$i ;} 2>/dev/null && exec >&\$i-"
    echo "done"
    echo ""
    
    echo "\$Tini \$Dbus $Hostexe $( [ "$Forwardstdin" = "yes" ] && echo "<$Cmdstdinfifo") >>$Cmdstdoutlogfile 2>>$Cmdstderrlogfile &"
    echo 'storeinfo pid1pid=$!'
  } >> $Containerrc
  nl -ba <$Containerrc >> $Containerlogfile

  # Send signal to run X and wait for X to be ready
  storeinfo readyforX=ready
  waitforlogentry "$Xserver" "$Xinitlogfile" "xinitrc is ready" "$Xiniterrorcodes"
  
  # run start script
  unpriv "/usr/bin/env bash $Containerrc"         ### FIXME support --user

  return 0
}