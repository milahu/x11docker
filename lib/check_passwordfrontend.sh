check_passwordfrontend() {      # check password prompt frontend (pkexec, su, sudo, ...) (also option --pw)
  # check if x11docker can run docker without prompting for password
  [ "$Passwordfrontend" = "auto" ] && {
    command -v sudo >/dev/null && Passwordfrontend="sudo" || Passwordfrontend="su"
  }
  [ "$Passwordfrontend" = "none" ] && Passwordneeded="no"
  [ "$X11dockermode" = "exe" ]     && Passwordneeded="no"
  case $Mobyvm in
    yes) Passwordneeded="no" && Passwordfrontend="none" ;;
  esac
  [ -z "$Passwordfrontend" ] && $Containerbackendbin info >/dev/null 2>&1 && Passwordfrontend="none" && Passwordneeded="no"
  [ -z "$Passwordfrontend" ] && sudo -n env >/dev/null 2>&1     && Passwordfrontend="sudo" && Passwordneeded="no"
  [ "$Passwordfrontend" = "sudo" ] && sudo -n env >/dev/null 2>&1 && Passwordneeded="no"

  # check sudo. Check is not reliable, compare https://unix.stackexchange.com/questions/383918/su-or-sudo-how-to-know-which-one-will-work
  ### FIXME: just guessing that members of group sudo or wheel are allowed to run commands docker and env as root
  [ -z "$Passwordfrontend" ] && { sudo -ln $Containerbackendbin >/dev/null 2>&1  ||  id | grep -q '(sudo)'  ||  id | grep -q '(wheel)' ; } && command -v sudo >/dev/null && {
    [ -z "$Hostdisplay$Newdisplay" ] && Passwordfrontend="sudo"
    sudo -ln env >/dev/null 2>&1  ||  id | grep -q '(sudo)'  ||  id | grep -q '(wheel)'  && {
      [ -z "$Passwordfrontend" ] && [ "$Runsinterminal" = "yes" ] && Passwordfrontend="sudo"
      [ -z "$Passwordfrontend" ] && command -v gksudo  >/dev/null && Passwordfrontend="gksudo"
      [ -z "$Passwordfrontend" ] && command -v lxsudo  >/dev/null && Passwordfrontend="lxsudo"
      [ -z "$Passwordfrontend" ] && command -v kdesudo >/dev/null && Passwordfrontend="kdesudo"
    }
    [ -z "$Passwordfrontend" ] && Passwordfrontend="sudo"
  }

  # check su
  [ -n "$Hostdisplay$Newdisplay" ] && {
    [ -z "$Passwordfrontend" ] && [ "$Runsinterminal" = "yes" ] && Passwordfrontend="su"
    [ -z "$Passwordfrontend" ] && command -v gksu  >/dev/null   && Passwordfrontend="gksu"
    [ -z "$Passwordfrontend" ] && command -v lxsu  >/dev/null   && Passwordfrontend="lxsu"
    [ -z "$Passwordfrontend" ] && command -v kdesu >/dev/null   && Passwordfrontend="kdesu"
    [ -z "$Passwordfrontend" ] && command -v beesu >/dev/null   && Passwordfrontend="beesu"
  }
  [ -z "$Passwordfrontend" ] && Passwordfrontend="su" # default if everything else fails

  # Passwordcommand: prefix to start dockerrc. Sudo: prefix to start docker in dockerrc
  case $Passwordfrontend in
    pkexec|"") Passwordcommand="bash -c"                                                 ; Passwordterminal="bash -c" ;;
    su)        Passwordcommand="su -c"                                                   ;;
#    sudo)      Passwordcommand="bash -c"                                                 ; Sudo="sudo -E " ;;
    sudo)      Passwordcommand="bash -c"                                                 ; Sudo="sudo " ;;
    gksu)      Passwordcommand="gksu    --message 'x11docker $Imagename' --disable-grab" ; Passwordterminal="bash -c" ;;
    gksudo)    Passwordcommand="gksudo  --message 'x11docker $Imagename' --disable-grab" ; Passwordterminal="bash -c" ;;
    lxsu)      Passwordcommand="lxsu"                                                    ; Passwordterminal="bash -c" ;;
    lxsudo)    Passwordcommand="lxsudo"                                                  ; Passwordterminal="bash -c" ;;
    kdesu)     Passwordcommand="kdesu -c"                                                ; Passwordterminal="bash -c" ;;
    kdesudo)   Passwordcommand="kdesudo --comment 'x11docker $Imagename'"                ; Passwordterminal="bash -c" ;;
    beesu)     Passwordcommand="beesu -c"                                                ; Passwordterminal="bash -c" ;;
    none)      Passwordcommand="bash -c"                                                 ; Passwordterminal="bash -c" ;;
    *) warning "Unknown password prompt '$Passwordfrontend' (option --pw).
  Possible: su sudo gksu gksudo lxsu lxsudo kdesu kdesudo beesu pkexec none"
               Passwordcommand="$Passwordfrontend"                                       ; Passwordterminal="bash -c" ;;
  esac
  [ "$Passwordneeded" = "yes" ] && {
    command -v $(echo $Passwordcommand|cut -d' ' -f1) >/dev/null || {
      warning "Password prompt frontend $(echo $Passwordcommand|cut -d' ' -f1) not found.
  Fallback: using no password prompt (--pw=none)." 
      check_fallback
               Passwordcommand="bash -c" ; Passwordfrontend="none" ; Passwordneeded="no" ; Passwordterminal="bash -c"
    }
  }
  [ "$Passwordcommand" = "bash -c" ] && Passwordcommand="eval"
  return 0
}