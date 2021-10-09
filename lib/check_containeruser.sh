check_containeruser() {         # check container user and shared home folder (also option --user)
  ## check container user
  [ "$Containeruser" = "RETAIN" ] && return 0
  [ -z "$Containeruser" ] && Containeruser="$Hostuser"               # default: containeruser = hostuser. can be changed with --user
  [ -n "$Containeruser" ] && echo "$Containeruser" | grep -q ':' && {  # option --user can specify a group/gid after :
    Containerusergid="$(echo "$Containeruser" | cut -d: -f2)"
    Containeruser="$(echo "$Containeruser" | cut -d: -f1)"
  }
  [ "$Containeruser" = "root" ] && Containeruser="0"
  [ -n "$(getent passwd "$Containeruser")" ] && {                      # user exists on host
    Containeruser=$(getent passwd "$Containeruser" | cut -d: -f1)      # can be name or uid -> now name
    Containeruseruid=$(getent passwd "$Containeruser" | cut -d: -f3)
    [ -z "$Containerusergid" ] && Containerusergid="$(getent passwd $Containeruser | cut -d: -f4)"
    [ "$Containeruser" = "$Hostuser" ] && Containeruserhosthome="$Hostuserhome"
    [ -z "$Containeruserhosthome" ]    && Containeruserhosthome="$(getent passwd "$Containeruser" | cut -d: -f6)"
    :
  } || {                                                   # user does not exist on host
    [[ "$Containeruser" =~ ^[0-9]+$ ]] || error "Option --user: Unknown host user or invalid user number '$Containeruser'.
  Non-host users can be specified with an UID only, not with a name."
    Containeruseruid="$Containeruser"
    Containeruser="unknown$Containeruseruid"
    [ -z "$Containerusergid" ] && Containerusergid=100
    Containeruserhosthome=""
  }
    
  Containerusergroup="$(getent group $Containerusergid | cut -d: -f1 || echo group_$Containeruser)"
  [ "$Containeruseruid" = "0" ] && {
    Containeruser="root"
    Containerusergid="0"
    Containerusergroup="root"
    Containeruserhosthome="/root"
    Sudouser="${Sudouser:-yes}" && note "Option --user=root: Enabling option --sudouser."
  }
  
  [ -f "$Passwordfile" ] && {
    verbose "Found password file $Passwordfile"
    Containeruserpassword="$(cat "$Passwordfile")"
    case "$(stat -c '%a' "$Passwordfile")" in
      600|400) ;;
      *) warning "File $Passwordfile
  should be readable by current user only.
  Please set access permissions to 600 or 400." ;;
    esac
  }
  [ -z "$Containeruserpassword" ] && Containeruserpassword='sac19FwGGTx/A' # password: x11docker

  store_runoption env "USER=$Containeruser"
  debugnote "container user: $Containeruser $Containeruseruid:$Containerusergid $Containeruserhosthome"

  case $X11dockermode in
   run) 
     case $Containersetup in
       no)  store_runoption env "XDG_RUNTIME_DIR=/tmp" ;;
     esac
   ;;
   exe)     store_runoption env "XDG_RUNTIME_DIR=$XDG_RUNTIME_DIR" ;;
  esac
  return 0
}