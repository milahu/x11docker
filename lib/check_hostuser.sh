check_hostuser() {              # check for unprivileged host user
  # check host user, want an unprivileged one to run X server
  # default behaviour:
  #  x11docker started as unprivileged user:          starting X server as this user and create same user in container
  #  x11docker started as root:                       determine real user with $(logname), instead of root use real user like above
  #  x11docker started as root with --hostuser=root:  root runs X server and root is container user (discouraged)
  #                                                   if you want root in container, just use --user=root
  #  x11docker with --user=someuser                   container user is someuser, host user is unprivileged user $(logname)
  #
  # root permissions are only needed to run docker. If started unprivileged, a password prompt appears.

  # user who started x11docker
  Startuser="$(id -un)"

  # not root? Use current user.
  [ -z "$Hostuser" ] && [ "$Startuser" != "root" ] && Hostuser="$Startuser"

  # root? find unprivileged user
  Lognameuser="$(logname 2>/dev/null ||:)"
  [ -z "$Lognameuser" ] && [ -z "$Hostuser" ] && note "Your terminal seems to be not POSIX compliant.
  Command 'logname' does not return a value.
  Consider to use another terminal emulator.
  Fallback: Will try to check \$SUDO_USER and \$PKEXEC_UID."
  [ -z "$Lognameuser" ] && [ -n "${SUDO_USER:-}" ]  && Lognameuser="${SUDO_USER:-}"  && [ -z "$Hostuser" ] && note "Will use \$SUDO_USER = ${SUDO_USER:-} as host user."
  [ -z "$Lognameuser" ] && [ -n "${PKEXEC_UID:-}" ] && Lognameuser="${PKEXEC_UID:-}" && [ -z "$Hostuser" ] && note "Will use user with uid \$PKEXEC_UID = ${PKEXEC_UID:-} as host user."
  [ -z "$Lognameuser" ] &&                             Lognameuser="$Startuser"      && [ -z "$Hostuser" ] && note "Will use \$(id -un) = $Lognameuser as host user."

  # option --hostuser
  [ -z "$Hostuser" ] && Hostuser=$Lognameuser
  [ "$Hostuser" != "$Startuser" ] && {
    [ "$Startuser" = "root" ] || error "Option --hostuser: x11docker must run as root
   to choose a host user different from user '$Startuser'."
  }
  getent passwd $Hostuser >/dev/null 2>&1 || {
    [ -e /etc/passwd ] || warning "Your system misses /etc/passwd"
    warning "Could not find user '$Hostuser' in /etc/passwd."
  }
  
  Hostuser=$(id -un $Hostuser)
  Hostuseruid=$(id -u $Hostuser)
  Hostusergid=$(id -g $Hostuser)
  [ "$Hostuser" = "$Startuser" ] && Hostuserhome="$HOME"
  
  [ -z "$Hostuserhome" ] && Hostuserhome=$(getent passwd $Hostuser 2>/dev/null | cut -d: -f6)
  [ -z "$Hostuserhome" ] && {
    Hostuserhome="/tmp/home/$Hostuser"
    mkdir -p "$Hostuserhome"
    warning "Could not read your home directory from /etc/passwd for user '$Hostuser'.
  Please set \$HOME with a valid path.
  Fallback: setting HOME=$Hostuserhome"
    check_fallback
  }
  debugnote "host user: $Hostuser $Hostuseruid:$Hostusergid $Hostuserhome"

  [ "$Hostuser" = "root" ] && warning "Running as user root.
  Maybe \$(logname) did not provide an unprivileged user.
  Please use option --hostuser=USER to specify an unprivileged user.
  Otherwise, new X server runs as root, and container user will be root."
  
  id | grep -q "(docker)" && warning "User $Hostuser is member of group docker.
  That allows unprivileged processes on host to gain root privileges."
  
  # How to run as unprivileged user in unpriv()
  case "$Hostuser" in
    "$Startuser") Unpriv="eval" ;;   # alternatively: bash -c
    *)            Unpriv="su $Hostuser -c" ;;
  esac
  
  return 0
}