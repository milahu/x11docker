start_pulseaudiotcp() {         # option --pulseaudio=tcp: load Pulseaudio TCP module (authenticated with container IP)
  local Containerip
  Containerip="$(storeinfo dump containerip)"
  Pulseaudiomoduleid="$(unpriv "pactl load-module module-native-protocol-tcp  port=$Pulseaudioport auth-ip-acl=${Containerip:-"127.0.0.1"}" )"
  [ "$Pulseaudiomoduleid" ] && {
    storeinfo "pulseaudiomoduleid=$Pulseaudiomoduleid"
  } || note "Option --pulseaudio: command pactl failed.
  Is pulseaudio running at all on your host?
  You can try option --alsa instead."
  return 0
}