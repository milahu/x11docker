setup_webcam() {                # option --webcam: share webcam devices
  # Webcam devices appear as /dev/video* files. 
  # Unprivileged users need to be in group video.
  # (This works only if webcam is plugged in before container starts.
  # Hotplug support would have to be different.)
  local Webcamdevice
  
  while read -r Webcamdevice ; do
    store_runoption volume "$Webcamdevice"
  done < <(find /dev/video* -maxdepth 0 2>/dev/null || note "Option --webcam: No webcam devices /dev/video* found.
  Webcam in container will fail.")
  Containerusergroups="$Containerusergroups video"
  
  # at least cheese and gnome-ring need some device information from udev.
  store_runoption volume "/run/udev/data:ro"
}