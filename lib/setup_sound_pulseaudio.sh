setup_sound_pulseaudio() {      # option --pulseaudio: set up pulseaudio connection
  # Allowing container access to Pulseaudio on host can be done with a shared socket or over TCP.
  # Sharing host user socket in XDG_RUNTIME_DIR fails since Pulseaudio v12.0.
  # Instead, a new socket is created with pactl.
  # TCP module is created after container startup to authenticate it with container IP.
  # Detailed documentation at: https://github.com/mviereck/x11docker/wiki/Container-sound:-ALSA-or-Pulseaudio
  #
  # g  $Pulseaudiomode    =tcp or =socket: Connect over tcp or with shared socket
  # g  $Pulseaudioport    TCP port
  local Lowerport= Upperport=
  local Pulseaudiopath

  warning "Option --pulseaudio allows container applications
  to catch your audio output and microphone input."
  
  [ -z "$Pulseaudiomode" ] && Pulseaudiomode="socket" 
  [ "$Pulseaudiomode" = "auto" ] && {
    Pulseaudiomode="socket" 
    [ "$Containeruser" = "$Hostuser" ]               || Pulseaudiomode="tcp"
    [ "$Runtime" = "kata-runtime" ]                  && Pulseaudiomode="tcp"
    [ "$Snapsupport" = "yes" ]                       && Pulseaudiomode="tcp"
    LC_ALL=C pactl info | grep -q "User Name: pulse" && Pulseaudiomode="tcp"
  }
  
  case $Pulseaudiomode in
    socket)
      # create pulseaudio socket
      Pulseaudiomoduleid="$(unpriv "pactl load-module module-native-protocol-unix socket=$Pulseaudiosocket 2>&1")"
      [ "$Pulseaudiomoduleid" ] && {
        storeinfo "pulseaudiomoduleid=$Pulseaudiomoduleid"
        store_runoption env "PULSE_SERVER=unix:$(convertpath share $Pulseaudiosocket)"
        store_runoption env "PULSE_COOKIE=$(convertpath share $Pulseaudiocookie)"
      } || {
        note "Option --pulseaudio: command pactl failed.
  Is pulseaudio running at all on your host?
  Fallback: Enabling option --alsa"
        check_fallback
        Pulseaudiomode=""
        Sharealsa="yes"
      }

      echo "# Connect to host pulseaudio server using mounted UNIX socket
default-server = unix:$(convertpath share $Pulseaudiosocket)
# Prevent a server running in container
autospawn = no
daemon-binary = /bin/true
# Prevent use of shared memory
enable-shm = false
" >> $Pulseaudioconf
        verbose "Generated pulseaudio client.conf:
$(nl -ba <$Pulseaudioconf)"
    ;;
    tcp)
      read Lowerport Upperport < /proc/sys/net/ipv4/ip_local_port_range 2>/dev/null
      [ "$Lowerport" ] || Lowerport=33000
      [ "$Upperport" ] || Upperport=60000
      while : ; do
        Pulseaudioport="$(shuf -i $Lowerport-$Upperport -n1)"
        ss -lpn | grep -q ":$Pulseaudioport " || break
      done
      [ -e "$Hostuserhome/.config/pulse/cookie" ] && cp "$Hostuserhome/.config/pulse/cookie" "$Pulseaudiocookie" || note "Option --pulseaudio: Did not find cookie
  $Hostuserhome/.config/pulse/cookie"
      store_runoption env "PULSE_SERVER=tcp:$Hostip:$Pulseaudioport"
    ;;
  esac
  return 0
}