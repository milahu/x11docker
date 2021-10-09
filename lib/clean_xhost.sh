clean_xhost() {                 # option --clean-xhost: disable xhost policies on host X
  [ -z "$Hostdisplay" ] && note "Option --clean-xhost: No host X display found." && return 1
  [ -z "$Hostxauthority" ] && warning "Option --clean-xhost: You host X server does not provide
  an authentication cookie in \$XAUTHORITY.
  Host applications started after xhost cleanup might fail to start."
  echo "Option --clean-xhost:" 2>&1 >> $Xinitlogfile
  DISPLAY="$Hostdisplay" XAUTHORITY="$Hostxauthority" disable_xhost 2>&1 >> $Xinitlogfile
}