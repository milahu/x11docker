setup_sound_alsa() {            # option --alsa: share sound devices
  # Sound with ALSA is directly supported by the kernel and only needs to share devices in /dev/snd.
  # libasound2 in image is recommended.
  # The desired sound card can be specified with environment variable ALSA_CARD. See card name in 'aplay -l'.
  # Further documentation at https://github.com/mviereck/x11docker/wiki/Container-sound:-ALSA-or-Pulseaudio

  warning "ALSA sound with option --alsa degrades container isolation.
  Shares device files in /dev/snd, container gains access to sound hardware.
  Container applications can catch audio output and microphone input."

  [ "$Alsacard" ] && store_runoption env "ALSA_CARD=$Alsacard"

  pgrep pulseaudio >/dev/null && note "It seems that pulseaudio is running on your host.
  Pulseaudio can interfere with ALSA sound (option --alsa).
  Host sound may not work while container is playing sound and vice versa.
  Alternative: with pulseaudio on host and in image, use option --pulseaudio."
    
  [ -d /dev/snd ] && store_runoption volume "/dev/snd" || {
    warning "Option --alsa: /dev/snd not found.
  Sound support not possible."
    Sharealsa="no"
    return 1
  }
  
  [ -s "$Pulseaudioconf" ] || echo "# Connect to host pulseaudio server using mounted UNIX socket
default-server = none
# Prevent a server running in container
autospawn = no
daemon-binary = /bin/true
# Prevent use of shared memory
enable-shm = false
" >> $Pulseaudioconf
  
  [ "$Sharealsa" = "yes" ] && Containerusergroups="$Containerusergroups audio"

  return 0
}