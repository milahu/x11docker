check_containerhome() {         # options --home, --homedir, --homebasedir: check HOME of container user.
  ## option '--home':        Share folder ~/.local/share/x11docker/imagename with created container as its home directory
  ## option '--home=DIR':    Share custom host folder as home
  ## option '--homebasedir': Specify base folder here to store container home folders for --home
  
  # base home folder
  [ "$Hosthomebasefolder" ] && {                # --homebasedir
    Hosthomebasefolder="$(convertpath subsystem "$Hosthomebasefolder")"
    [ -e "$Hosthomebasefolder" ] || {
      warning "Option --homebasedir: Specified path does not exist:
  $Hosthomebasefolder
  Fallback: Using default home base directory."
      check_fallback
      Hosthomebasefolder=""
    }
  }
  [ "$Hosthomebasefolder" ] || case $Mobyvm in
    no)  Hosthomebasefolder="$Containeruserhosthome/.local/share/x11docker" ;;
    yes) Hosthomebasefolder="$(convertpath subsystem "$(wincmd 'echo %userprofile%') ")/x11docker/home" ;;
  esac
  
  case $Sharehome in
    yes|host)
      [ -z "$Persistanthomevolume" ] && Persistanthomevolume="$Hosthomebasefolder/$Imagebasename"
      Persistanthomevolume="$(sed "s%~%$Hostuserhome%" <<< "$Persistanthomevolume")"
      [ "${Persistanthomevolume:0:1}" = "/" ] && Sharehome="host" || Sharehome="volume"
    ;;
  esac

  case $Sharehome in
    host)  
      case $Createcontaineruser in
        no)
          note "Option --home or --home=DIR is not supported 
  with option --user=RETAIN.
  Alternatively, specify a docker volume with --home=VOLUME.
  Also you can use option --share to share host directories.
  Fallback: Disabling option --home."
          check_fallback
          Sharehome="no"
        ;;
        yes)
          grep -q "unknown" <<< "$Containeruser" && {
            note "Option --home: Sharing a host folder is allowed only
  for container users that also exist on host.
  You can use a docker volume with --home=VOLUME instead.
  Fallback: Disabling option --home."
            check_fallback
            Sharehome="no"
          }
        ;;
      esac
    ;;
  esac

  case $Sharehome in
    host)
      Containeruserhomebasefolder="/home" 
      # A change can break existing configs, e.g. playonlinux
#      Containeruserhomebasefolder="/home.x11docker" 
      [ "$Persistanthomevolume" = "$Containeruserhosthome" ] && {
        # --home=$HOME must be same as on host #243 
        Containeruserhomebasefolder="$(dirname "$Containeruserhosthome")"
        Containeruserhome="$Containeruserhosthome"
      }
    ;;
    no)     
#      Containeruserhomebasefolder="/home.tmp" 
      Containeruserhomebasefolder="/home" 
    ;;
    volume) 
      Containeruserhomebasefolder="/home.volume/$Persistanthomevolume" 
      grep -q "/" <<< "$Persistanthomevolume" && error "Option --home: Invalid argument: '$Persistanthomevolume'
  Please either specify an absolute path beginning with '/'
  or specify a docker volume without any '/'."
    ;;
  esac
  [ "$Createcontaineruser" = "yes" ] && Containeruserhome="${Containeruserhome:-$Containeruserhomebasefolder/$Containeruser}"
  [ "$Sharehome" != "no" ] && store_runoption env "HOME=$Containeruserhome"
    
#  case "$Createcontaineruser" in
#    no)  store_runoption env "HOME=/tmp" ;;
#  esac
  
  case $Sharehome in
    host)  
      # if no home folder on host is specified (--home=DIR), create a standard one in ~/.local/share/x11docker
      [ -d "$Persistanthomevolume" ] || {
        [ "$Startuser" = "root" ] && su $Containeruser -c "mkdir -p '$Persistanthomevolume'"
        [ "$Containeruser" = "$Hostuser" ] && unpriv "mkdir -p '$Persistanthomevolume'" && {
          # create symbolic link to ~/x11docker
          echo "$Persistanthomevolume" | grep -q .local/share/x11docker && [ ! -e "$Hostuserhome/x11docker" ] && unpriv "ln -s '$Hosthomebasefolder' '$Hostuserhome/x11docker'" ||:
        }
      }
      [ -d "$Persistanthomevolume" ] || error "Option --home: Could not create persistent home folder for
  user '$Containeruser' on host. Can e.g. happen with option --user.
  Four possibilities to solve issue:
  1.) Run x11docker one time as user '$Containeruser'.
  2.) Run x11docker one time as user 'root'.
  3.) Use option --home=DIR with DIR pointing to a writeable folder.
  4.) Use option --home=VOLUME to use a docker volume."
      writeaccess $Containeruseruid "$Persistanthomevolume" || warning "User '$Containeruser' might have no write access to
  $Persistanthomevolume."
      verbose "Sharing directory $Persistanthomevolume
  with container as its home directory $Containeruserhome"
    ;;
    volume)
      debugnote "Option --home: Using docker volume $Persistanthomevolume"
    ;;
  esac

  return 0
}