convertpath() {                 # convert unix and windows paths
  # $1: Mode:
  #     windows   echo Windows path                            - result: c:/path
  #     unix      echo unix path                               - result: /c/path
  #     subsystem echo path within subsystem                   - result: /cygdrive/c/path  or  /path  or /mnt/c/path
  #     volume    echo --volume compatible syntax              - result: 'unixpath':'containerpath':rw  (or ":ro")
  #     container echo path of volume in container             - result: /path
  #     share     echo path of $Sharefolder/file in container  - result: /containerpath
  # $2: Path to convert. Arbitrary syntax, can be C:/path, /c/path, /cygdrive/c/path, /path
  #     Can have suffix :rw or :ro. If none is given, return with :rw
  # $3: Optional for mode volume: containerpath
  
  local Mode Path Drive= Readwritemode
  
  Mode="${1:-}"
  Path="${2:-}"

  # check path for suffix :rw or :ro
  Readwritemode="$(echo "$Path" | rev | cut -c1-3 | rev)"
  [ "$(cut -c1 <<< "$Readwritemode")" = ":" ] && {
    Path="$(echo "$Path" | rev | cut -c4- | rev)"
  } || Readwritemode=":rw"

  # replace ~ with HOME
  Path="$(sed s%"~"%"${Hostuserhome:-${HOME:-}}"% <<< "$Path")"
  
  # share: Replace $Sharefolder with $Sharefoldercontainer
  [ "$Mode" = "share" ] && {
    [ -z "$Path" ] && echo "" && return 0
    case $X11dockermode in
      run)            echo "${Sharefoldercontainer}${Path#$Sharefolder}" ;;
      exe)            echo "$Path" ;;
    esac
    return 0
  }
  
  # replace \ with /
  Path="$(tr '\\' '/' <<< "$Path")"
  
  # remove possible already given mountpoint
  Path="${Path#$Winsubmount}"
  
  # Given format is /c/
  [ "$(cut -c1,3 <<< "$Path")" = "//" ] && {
    Drive="$(cut -c2 <<< "$Path")"
    Path="$(cut -c3- <<< "$Path")"
  }
  
  # Given format is C:/
  [ "$(cut -c2 <<< "$Path")" = ":" ] && {
    Drive="$(cut -c1 <<< "$Path")"
    Path="$(cut -c3- <<< "$Path")"
  }
  
  # change C to c
  Drive="${Drive,}"

  # docker volume
  [ "${Path:0:1}" = "/" ] || {
    case $Mode in
      unix|subsystem|windows) echo "$Path" ; debugnote "convertpath() $Mode: Docker volumes do not have a specified path on host: $Path" ;;
      volume)         echo "'$Path':'${3:-/$Path}'$Readwritemode" ;;
      container)      echo "${3:-/$Path}" ;;
    esac
    return 0
  }

  Containerpath="$Path"
  [ "$Sharehome" = "host" ] || {
    grep -q "^$Containeruserhome" <<< "$Path" && Containerpath="$(sed "s%^$Containeruserhome%/home.host%" <<< "$Containerpath")"
  }
  [ "$Containerpath" = "$Containeruserhosthome" ] && [ "$Persistanthomevolume" != "$Containeruserhosthome" ] && Containerpath="/home.host/$Containeruser"
  
  # not on Windows
  [ -z "$Winsubsystem" ] && {
    case $Mode in
      unix|subsystem) echo "$Path" ;;
      windows)        warning "convertpath(): Nonsense path conversion $Mode: $Path" ; return 1 ;;
      #volume)         echo "'$Path':'${3:-$Path}'$Readwritemode" ;;
      #container)      echo "${3:-$Path}" ;;
      volume)         echo "'$Path':'${3:-$Containerpath}'$Readwritemode" ;;
      container)      echo "${3:-$Containerpath}" ;;
    esac
    return 0
  }
  
  case $Winsubsystem in
    WSL1)
      [ -z "$Drive" ] && case $Mode in
        windows|unix|volume)
          debugnote "convertpath(): Request of WSL path: $Path"
          grep -q "$Cachefolder" <<< "$Path" || {
            [ "$Readwritemode" = ":rw" ] && warning "Request of Windows path to path within WSL:
  $Path
  Write access from Windows host to WSL files can damage the WSL file system. 
  Read-only access is ok. 
  Option --share: You can add :ro to the path to allow read-only access.
  Example: --share='$Path:ro'"
          }
        ;;
      esac
    ;;
  esac

  case $Drive in
    "") # Path points into subsystem
      Path="${Path#"$Winsubpath"}"
      Drive="$(cut -c2 <<<"$Winsubpath")"
      case $Mode in
        windows)      echo "${Drive^}:$(cut -c3- <<<$Winsubpath)$Path" ;;
        unix)         echo "$Winsubpath$Path" ;;
        subsystem)    echo "$Path" ;;
        volume)
          case $Mobyvm in
            no)  echo "'$Path':'${3:-$Path}'$Readwritemode" ;;
            yes) echo "'$Winsubpath$Path':'${3:-$Path}'$Readwritemode" ;;
          esac
        ;;
        container)    echo "${3:-$Path}" ;;
      esac
    ;;
    *) # Path outside of subsystem
      case $Mode in
        windows)      echo "${Drive^}:$Path" ;;
        unix)         echo "/$Drive$Path" ;;
        subsystem)    echo "$Winsubmount/$Drive$Path" ;;
        volume)       echo "'/$Drive$Path':'${3:-/$Drive$Path}'$Readwritemode" ;;
        container)    echo "${3:-/$Drive$Path}" ;;
      esac
    ;;
  esac
  
  return 0
}