installer() {                   # --install, --update, --update-master, --remove: Installer for x11docker
  # --install:
  #   - copies x11docker and x11docker-gui to /usr/bin
  #   - installs icon in /usr/share/icons
  #   - creates x11docker.desktop file in /usr/share/applications
  # --update:
  #   - download and install latest release from github, regard existing installation location
  # --update-master:
  #   - download and install latest master version from github, regard existing installation location
  # --remove
  #   - remove installed files
  
  ### FIXME: (--update)
  ### do not require sudo if installed x11docker is owned by user
  ### do not install x11docker-gui if not present
  ### maybe not install additional files if x11docker is owned by user
  local Key1= Key2= Oldversion= Newversion= Format= 
  local Binpath Binowner Bingroup Binpathdefault
  
  Binpathdefault="/usr/bin"
  # Detect existing installation location
  case ${1:-} in
    --install)
      Binpath="$Binpathdefault"
    ;;
    --update|--update-master|--remove)
      grep -q x11docker <<< "$0" && {
        Binpath="$(dirname "$0")"
        Binpath="$(myrealpath "$Binpath")"
        Binowner="$(stat -c '%U' "$0")"
        Bingroup="$(stat -c '%G' "$0")"
        [ -d "$Binpath/.git" ] && error "Option ${1:-}: It seems you are within a git directory.
  Use 'git pull' to update your local git repository.
  Otherwise, run 'x11docker --install' first
  before running 'x11docker ${1:-}'
  so to use a system installation of x11docker."
      }
    ;;
  esac
  Binpath="${Binpath:-$Binpathdefault}"
  Binowner="${Binowner:-root}"
  Bingroup="${Bingroup:-root}"
  [ "$Binpath" != "$Binpathdefault" ] && note "Option ${1:-}: Detected custom installation path:
  $Binpath"
  
  [ "$Startuser" != "root" ] && {
    case "$Winsubsystem" in
      CYGWIN|MSYS2) ;;
      *) 
        case "$Binowner" in
          root) error "Must run as root to install, update or remove x11docker system wide." ;;
          *) warning "Option ${1:-}: Not running as root.
  Installing or updating non-essential files in system wide folders might fail." ;;
        esac
      ;;
    esac
  }

  # Preparing
  case ${1:-} in
    --install)
      [ -f "./x11docker" ]             || { error "File x11docker not found in current folder.
  Try 'x11docker --update' instead." ; }
      command -v x11docker > /dev/null && { warning "x11docker seems to be installed already.
  Will overwrite existing installation.
  Consider to use option '--update' or '--update-master' instead." ; }
    ;;
    --update|--update-master)
      grep -q x11docker <<< "$0" && {
        Oldversion="$($0 --version)"
        note "Current installed version: x11docker $Oldversion"
      } || {
        Oldversion=""
      }

      [ -d /tmp/x11docker-install ] && rm -R /tmp/x11docker-install
      mkdir -p /tmp/x11docker-install && cd /tmp/x11docker-install || error "Could not create or cd to /tmp/x11docker-install."
      download || error "Neither wget nor curl found. Need 'wget' or 'curl' for download.
  Please install wget or curl."
      command -v unzip >/dev/null && Format="zip"
      command -v tar >/dev/null   && Format="tar.gz"
      [ "$Format" ] || error "Cannot extract archive. Please install 'unzip' or 'tar'."

      case ${1:-} in
        --update-master)
          note "Downloading latest x11docker master version from github."
          download "https://codeload.github.com/mviereck/x11docker/$Format/master" "x11docker-update.$Format"           || error "Failed to download x11docker from github."
        ;;
        --update)
          download "https://raw.githubusercontent.com/mviereck/x11docker/master/CHANGELOG.md" "CHANGELOG.md"            || error "Failed to download CHANGELOG.md from github."
          Releaseversion="v$(cat CHANGELOG.md | grep "## \[" | grep -v 'Unreleased' | head -n1 | cut -d[ -f2 | cut -d] -f1)"
          note "Downloading latest x11docker release $Releaseversion from github."
          download "https://codeload.github.com/mviereck/x11docker/$Format/$Releaseversion" "x11docker-update.$Format"  || error "Failed to download x11docker from github."
        ;;
      esac

      note "Extracting $Format archive."
      case $Format in
        zip)    unzip   "x11docker-update.$Format" ;;
        tar.gz) tar xzf "x11docker-update.$Format" ;;
      esac || error "Failed to extract $Format archive."
      echo ""
      cd /tmp/x11docker-install/$(ls -l | grep drwx | rev | cut -d' ' -f1 | rev) || error "Could not cd to /tmp/x11docker-update/$(ls -l | grep drwx | rev | cut -d' ' -f1 | rev)"
    ;;
  esac

  # Doing
  case ${1:-} in
    --install|--update|--update-master)
      note "Installing x11docker and x11docker-gui in $Binpath"
      cp x11docker "$Binpath/"                                                || error "Could not copy x11docker to $Binpath"
      chmod 755 "$Binpath/x11docker"                                          || error "Could not set executable bit on x11docker"
      chown "$Binowner:$Bingroup" "$Binpath/x11docker"                        || warning "Could not set ownership '$Binowner:$Bingroup' to '$Binpath/x11docker'"
      cp x11docker-gui "$Binpath/" && {
        chmod 755 "$Binpath/x11docker-gui"
        chown "$Binowner:$Bingroup" "$Binpath/x11docker-gui"                  || warning "Could not set ownership '$Binowner:$Bingroup' to '$Binpath/x11docker-gui'"      
      } || warning "x11docker-gui not found"

      note "Installing icon for x11docker with xdg-icon-resource"
      xdg-icon-resource install --context apps --novendor --mode system --size 64 "$(pwd)/x11docker.png" x11docker || warning "Could not install icon for x11docker.
  Is 'xdg-icon-resource' (xdg-utils) installed on your system?"
      xdg-icon-resource uninstall --size 72 x11docker ||:  # deprecated icon size, may still be present.

      note "Creating application entry for x11docker."
      [ -e "$Binpath/x11docker-gui" ] && {
        echo "[Desktop Entry]
  Version=1.0
  Type=Application
  Name=x11docker
  Comment=Run GUI applications in docker images
  Exec=x11docker-gui
  Icon=x11docker
  Categories=System
" > /usr/share/applications/x11docker.desktop
      } || note "Did not create desktop entry for x11docker-gui"
      command -v kaptain >/dev/null || note "Could not find 'kaptain' for x11docker-gui.
  Consider to install 'kaptain' (version 0.73 or higher).
  It's useful for x11docker-gui only, though. x11docker itself doesn't need it.
  If your distributions does not provide kaptain, look at kaptain repository:
    https://github.com/mviereck/kaptain
  Fallback: x11docker-gui will try to use image x11docker/kaptain."

      note "Storing README.md, CHANGELOG.md and LICENSE.txt in
  /usr/share/doc/x11docker"
      mkdir -p /usr/share/doc/x11docker && {
        cp README.md    /usr/share/doc/x11docker/
        cp CHANGELOG.md /usr/share/doc/x11docker/
        cp LICENSE.txt  /usr/share/doc/x11docker/
      } || note "Error while creating /usr/share/doc/x11docker"

      Newversion="$("$Binpath/x11docker" --version)"
      note "Installed x11docker version $Newversion"
    ;;
    --remove)
      note "Removing x11docker from your system."
      cleanup
      [ -x "$Binpath/x11docker" ] && {
        rm -v "$Binpath/x11docker"
        rm -v "$Binpath/x11docker-gui"
      }
      [ -e "/usr/share/applications/x11docker.desktop" ] && rm -v /usr/share/applications/x11docker.desktop
      [ -e "/usr/share/doc/x11docker" ]                  && rm -R -v /usr/share/doc/x11docker
      [ -e "/usr/share/icons/x11docker.png" ]            && rm /usr/share/icons/x11docker.png
      xdg-icon-resource uninstall --size 64 x11docker ||:
      xdg-icon-resource uninstall --size 72 x11docker ||:  # deprecated icon size, may still be present.
      note "Will not remove files in your home folder.
  There may be files left in \$HOME/.local/share/x11docker
  The symbolic link \$HOME/x11docker may exist, too.
  The cache folder \$HOME/.cache/x11docker should be removed already."
    ;;
  esac

  # Cleanup
  case ${1:-} in
    --update|--update-master)
      note "Removing downloaded temporary files."
      cd ~
      rm -R /tmp/x11docker-install
    ;;
  esac

  # Changelog excerpt
  case ${1:-} in
    --update)
      echo "$Oldversion" | grep -q beta && {
        warning "You are switching from master branch to stable releases.
  To get latest master beta version, use option --update-master instead"
        Key1="\[${Newversion}\]"
        Key2="https:\/\/github.com\/mviereck\/x11docker\/releases"
      } || {
        Key1="\[${Newversion}\]"
        Key2="\[${Oldversion}\]"
        [ "$Newversion" = "$Oldversion" ] && {
          Key2="https:\/\/github.com\/mviereck\/x11docker\/releases"
          note "Version $Newversion was already installed before this update.
  If you want the latest beta version from master branch, use --update-master."
        }
        [ -z "$Oldversion" ] && Key2="https:\/\/github.com\/mviereck\/x11docker\/releases"
      }
    ;;
    --update-master)
      echo "$Oldversion" | grep -q beta && {
        Key1="\[Unreleased\]"
        Key2="https:\/\/github.com\/mviereck\/x11docker\/releases"
      } || {
        Key1="\[Unreleased\]"
        Key2="\[${Oldversion}\]"
        [ -z "$Oldversion" ] && Key2="https:\/\/github.com\/mviereck\/x11docker\/releases"
      }
    ;;
  esac
  case ${1:-} in
    --update|--update-master)
      note "Excerpt of x11docker changelog:
$(sed -n '/'$Key1'/,/'$Key2'/p' /usr/share/doc/x11docker/CHANGELOG.md | head -n-1)"
    ;;
  esac
  note "Ready."
}