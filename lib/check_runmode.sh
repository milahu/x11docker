check_runmode() {               # check run/--exe/--xonly
  # Basically x11docker divides between
  # default: run docker image
  # --exe:   run host executable
  # --xonly: run X server only (changes here to --exe with sleep)
  #
  [ -z "$Imagename" ] && X11dockermode="xonly"
  case $X11dockermode in
    run)
      Imagebasename="$(echo $Imagename | tr / - | cut -d: -f1)"
      Codename="$Imagename $Containercommand"
      
      command -v $Containerbackendbin >/dev/null || error "Backend $Containerbackendbin is not installed.
  To run containers you need to install a valid backend.
  Known backends: docker podman nerdctl"
      verbose "Image name: $Imagename
  Container command: $Containercommand"
    ;;
    exe)
      Hostexe="$Imagename $Containercommand"
      [ "$Customdockeroptions" ] && Hostexe="$Customdockeroptions -- $Hostexe" # might be a command like 'grep -- 'expr'
      Imagename=""
      Containercommand=""
      Imagebasename="$(basename "$Hostexe" | cut -d' ' -f1)"
      Codename="$Hostexe"
      command -v $Hostexe >/dev/null || error "Command '$Hostexe' not found."
      verbose "Host application to execute: $Hostexe"
    ;;
    xonly)
      X11dockermode="exe"
      Hostexe="sleep infinity"
      Imagename=""
      Containercommand=""
      Codename="xonly"
      Imagebasename="xonly"
      Showdisplayenvironment="yes"
    ;;
  esac
  Codename="$(unspecialstring "$Codename" | cut -c1-40)"
  Codename="${Codename:-noname}"
  Imagebasename="$(unspecialstring "$Imagebasename")"  # must be - for backwards compatibility of --home
  Imagebasename="${Imagebasename:-noname}"
  
  return 0
}