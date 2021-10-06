create_launcher() {             # --launcher: create application launcher on desktop
  local Name=
  
  command -v xdg-desktop-icon >/dev/null || error "Command 'xdg-desktop-icon' not found.
  x11docker needs it to place the new icon on your desktop.
  Please install xdg-utils"

  note "Will create a new application launcher icon on your desktop.
  If you move the new file to:

    $Hostuserhome/.local/share/applications

  it will appear in your applications menu."

  Name="$Codename"
  [ "$Codename" = "xonly" ] && Name="$(echo $Xserver | tr -d '-')"
  Name="${Name% }"

  read -re -p "Please choose a name for your application launcher:
" -i "$Name" Name
  [ -z "$Name" ] && return 1 ### FIXME: check for valid file name / invalid chars?

  Parsedoptions_global="${Parsedoptions_global//--launcher/}"
  Parsedoptions_global="${Parsedoptions_global//--starter/}"
  mkfile "$Cachefolder/$Name.desktop"
  {
    echo "#!/usr/bin/xdg-open
[Desktop Entry]
# x11docker desktop file
Type=Application
Name=$Name
Exec=x11docker $Parsedoptions_global
Icon=x11docker
Comment=
Categories=System
Keywords=docker x11docker $(echo $Name | tr -c '[:alpha:][:digit:][:blank:]' ' ' )
"
    case $(command -v x11docker) in
      "")echo "TryExec=$0 $Parsedoptions_global" ;;
      *) echo "TryExec=x11docker $Parsedoptions_global" ;;
    esac
  } >> "$Cachefolder/$Name.desktop"

  unpriv "xdg-desktop-icon install --novendor '$Cachefolder/$Name.desktop'"
}