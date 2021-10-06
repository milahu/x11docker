setup_capabilities() {          # check linux capabilities needed by container
  # compare: man capabilities

  [ "$Sudouser" ]               && Adminusercaps="yes"
  [ "$Capdropall" = "no" ]      && [ "$Allownewprivileges" = "auto" ] && { 
    note "Option --cap-default: Enabling option --newprivileges=yes.
  You can avoid this with --newprivileges=no"
    Allownewprivileges="yes"
  }
  
  # --sudouser
  [ "$Sudouser" ] && warning "Option --sudouser severely reduces container security.
  Container gains additional capabilities to allow sudo and su.
  If an application breaks out of container, it can harm your system
  in many ways without you noticing. Default password: x11docker"

  # enable dbus
  case $Initsystem in
    systemd|sysvinit|openrc|runit) Dbussystem="yes" ;;
  esac  
  [ "$Dbussystem" = "yes" ]    && {
    Dbusrunsession="yes"
    store_runoption cap "CHOWN FOWNER" ### FIXME: CHOWN needed indeed here?
    Switchcontaineruser="yes"
  }
  
  case $Initsystem in
    none|tini|dockerinit) ;;
    systemd)
      Switchcontaineruser="yes"
      Sharecgroup="yes"
      store_runoption cap "FSETID FOWNER SETPCAP SYS_BOOT"
    ;;
    runit|openrc|sysvinit)
      Switchcontaineruser="yes"
      store_runoption cap "SYS_BOOT KILL"
    ;;
    s6-overlay)
      Switchcontaineruser="yes"
      store_runoption cap "CHOWN KILL"
    ;;
  esac 

  [ "$Sharecgroup" = "yes" ]         && Switchcontaineruser="yes" # needed for elogind
  [ "$Switchcontaineruser" = "yes" ] && Switchcontainerusercaps="yes"
  
  [ "$Adminusercaps" = "yes" ] && {
    Switchcontainerusercaps="yes"
    store_runoption cap "CHOWN KILL FSETID FOWNER SETPCAP"
    [ "$Allownewprivileges" = "auto" ] && {
      note "Option --sudouser: Enabling option --newprivileges=yes.
  You can avoid this with --newprivileges=no"
      Allownewprivileges="yes"
    }
  }
  [ "$Switchcontainerusercaps" = "yes" ] && store_runoption cap "SETUID SETGID DAC_OVERRIDE AUDIT_WRITE"
  
  # Automated NVIDIA driver installation
  [ "$Sharegpu" = "yes" ] && [ "$Nvidiainstallerfile" ] && [ "$Switchcontaineruser" = "yes" ] && store_runoption cap "CHOWN FOWNER"
  
  [ "$Allownewprivileges" = "auto" ] && Allownewprivileges="no"
  
  [ "$Allownewprivileges" = "yes" ] && warning "Option --newprivileges=yes: x11docker does not set 
  docker run option --security-opt=no-new-privileges. 
  That degrades container security.
  However, this is still within a default docker setup."
  
  # Issues with hidepid=2 seen on NixOS (issue #83)
  { [ "$Switchcontaineruser" = "yes" ] || [ "$Containeruser" != "$Hostuser" ] ; } && {
    [ "$Hostcanwatchroot" = "no" ] && {
      [ "$Hosthidepid" = "yes" ]            && Message="/proc is mounted with hidepid=2." || Message="Cannot watch processes of other users for unknown reasons."
      Message="$Message
  x11docker cannot watch processes of root
  or other users different from $Hostuser."
      [ "$Hostuser" != "$Containeruser" ]   && Message="$Message
  Container user $Containeruser is different from host user $Hostuser."
      [ "$Switchcontaineruser" = "yes" ]    && Message="$Message
  Container PID 1 will run as root."
      Message="$Message
  Therefore x11docker cannot watch container processes
  for a clean termination of X and x11docker itself.
  Four possible solutions:
    1. Run x11docker as root.
    2. Don't use options like --user or --init=systemd that change container user.
    3. Add user $Hostuser to group 'proc'.
    4. Change /proc mount option hidepid=2 to hidepid=1."
      error "$Message"
    }
  }
  
  return 0
}