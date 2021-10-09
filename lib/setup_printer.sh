setup_printer() {               # option --printer: connect to cups printer server
  # Default CUPS setups create a unix socket /run/cups/cups.sock as given from 'lpstat -H'.
  # Sharing this socket and pointing environment variable CUPS_SERVER to it serves most cases.
  # Possible CUPS network setups need to allow access from container, see note below.
  local Cupsserver=
  
  command -v lpstat >/dev/null || {
    warning "Option --printer: command lpstat not found.
  Is cups printer server installed on your system?
  Error: Cannot share access to printer."
    Sharecupsmode=""
    return 1
  }
  
  case $Sharecupsmode in
    tcp)    Cupsserver="$Hostip:631" ;;
    socket) Cupsserver="$(lpstat -H)" ;;
  esac
  
  grep -q ":" <<<$Cupsserver && {
    [ "$(cut -d: -f1 <<<$Cupsserver)" = "localhost" ] && Cupsserver="$Hostip:$(cut -d: -f2 <<<$Cupsserver)"
    [ "$(cut -d: -f1 <<<$Cupsserver)" = "127.0.0.1" ] && Cupsserver="$Hostip:$(cut -d: -f2 <<<$Cupsserver)"
    note "Option --printer: Network setup for CUPS detected.
  Server address: $Cupsserver
  You may need to allow container access in /etc/cups/cupsd.conf, e.g.:

Port 631
<Location />
  # Allow remote access...
  Order allow,deny
  Allow 172.17.0.*
  Allow 127.0.0.1
</Location>"
  }
    
  [ "$Cupsserver" ]    && store_runoption env "CUPS_SERVER=$Cupsserver"
  [ -e "$Cupsserver" ] && {
    [ "$(dirname $Cupsserver)" = "/run/cups" ] && store_runoption volume "/run/cups" || store_runoption volume "$Cupsserver"
  }
  
  return 0
}