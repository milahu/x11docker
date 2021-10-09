start_docker() {                # start xtermrc -> dockerrc
  # run docker in xtermrc, ask for password if needed
  case $Passwordfrontend in
    su|sudo)
      case $Passwordneeded in
        no)                     /usr/bin/env bash $Xtermrc ;;
        yes) $Passwordterminal  /usr/bin/env bash $Xtermrc ;;
      esac
    ;;
    *)       $Passwordterminal              "bash $Xtermrc" ;;
  esac
  waitforlogentry "start_docker()" "$Storeinfofile" "dockerrc=ready" "" infinity
}