setup_gpu() {                   # option --gpu: share /dev/dri and check nvidia driver
  # Easiest case: share /dev/dri.
  # Works for open source MESA drivers on host and in image.
  # Debian packages for MESA drivers in image: libgl1-mesa-dri, libglx-mesa0
  #
  # Closed source NVIDIA drivers does not integrate well within linux.
  # Instead, free nouveau driver is a better choice, or no NVIDIA hardware at all.
  # Possibilities:
  # - Install NVIDIA driver in image. It must be the very same version as on your host.
  #   The image is not portable anymore.
  # - x11docker can install NVIDIA driver on the fly in running container. See notes below.
  #
  # g  $Nvidiainstallerfile   nvidia driver file to install in container in containerrootrc
  # g  $Nvidiaversion  nvidia driver version on host

  local Gpudevice
  
  Containerusergroups="$Containerusergroups video render"

  # check device files
  while read -r Gpudevice ; do
    store_runoption volume "$Gpudevice"
  done < <(find /dev/dri /dev/nvidia* /dev/vga_arbiter /dev/nvhost* /dev/nvmap -maxdepth 0 2>/dev/null ||:)

  #Nvidiaversion="304.137"
  [ -z "$Nvidiaversion" ] && return 0
  
  # check for closed source nvidia driver on host, provide automated installation, warn about disadvantages
  debugnote "NVIDIA: Detected driver version $Nvidiaversion on host."
  
  [ "$Runtime" = "nvidia" ] && {
    debugnote "NVIDIA: Option --runtime=nvidia: Skipping driver installation."
    Nvidiainstallerfile="" 
    return 0
  }
  
  Nvidiainstallerfile="$(find /usr/local/share/x11docker/NVIDIA*$Nvidiaversion*.run $Hostuserhome/.local/share/x11docker/NVIDIA*$Nvidiaversion*.run 2>/dev/null | tail -n1 )"
  Nvidiainstallerfile="$(myrealpath "$Nvidiainstallerfile" 2>/dev/null)"
  
  [ -e "$Nvidiainstallerfile" ] && {
    debugnote "NVIDIA: Found proprietary closed source NVIDIA driver installer
  $Nvidiainstallerfile"
    [ "$Containersetup" = "no" ] && {
      note "Options --no-setup --gpu: Cannot install NVIDIA driver
  with option --no-setup. Fallback: Disabling option --gpu"
      Sharegpu="no"
      return 1
    }
    [ "$Capdropall" = "yes" ] && warning "Option --gpu: Installing NVIDIA driver in container
  requires container privileges that x11docker would drop otherwise.
  Though, they are still within default docker capabilities."
    Allownewprivileges="yes"
    store_runoption cap CHOWN
    store_runoption cap FOWNER
    return 0
  }
  
  Nvidiainstallerfile=""
  
  note "Option --gpu: You are using the closed source NVIDIA driver.
  GPU acceleration will only work if you have installed the very same driver
  version in image. That makes images less portable.
  It is recommended to use free open source nouveau driver on host instead.
  Ask NVIDIA corporation to at least publish their closed source API,
  or even better to actively support open source driver nouveau."

  note "Option --gpu: x11docker can try to automatically install NVIDIA driver
  version $Nvidiaversion in container on every container startup.
  Drawbacks: Container startup is a bit slower and its security will be reduced.

  You can look here for a driver installer file:
    https://www.nvidia.com/Download/index.aspx
    https://http.download.nvidia.com/
  A direct download URL is probably:
    https://http.download.nvidia.com/XFree86/Linux-x86_64/$Nvidiaversion/NVIDIA-Linux-x86_64-$Nvidiaversion.run
  If you got a driver, store it at one of the following locations:
    $Hostuserhome/.local/share/x11docker/
    /usr/local/share/x11docker/

  Be aware that the version number must match exactly the version on host.
  The file name must begin with 'NVIDIA', contain the version number $Nvidiaversion
  and end with suffix '.run'."
  
  return 0
}