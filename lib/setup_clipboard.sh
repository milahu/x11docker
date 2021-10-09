setup_clipboard() {             # option --clipboard: create shareclipboard script
  # Clipboard sharing works different depending on the new X server
  #  - xpra and nxagent have their own clipboard management.
  #  - Only xpra supports image clips.
  #  - --hostdisplay accesses the clipboard from host X directly
  #  - Other X servers: A script is created to synchronize clipboard between X servers.
  #  - No clipboard support for Wayland yet.
  # The script uses xclip or xsel. It is executed in xinitrc.
  
  local Clipsend= Clipreceive=
  
  case $Xserver in
    --tty|--weston|--hostwayland|--kwin)
      warning "Option --clipboard is not supported for $Xserver.
  Fallback: Disabling option --clipboard."
      check_fallback
      Shareclipboard="no"
      return 1
    ;;
    --nxagent|--xpra|--xpra-xwayland|--xwin) ;; # have their own clipboard management, look at create_xcommand().
    
    --xephyr|--xorg|--xdummy|--xdummy-xwayland|--xvfb|--xwayland|--weston-xwayland)
      # check for either xclip or xsel
      command -v xsel >/dev/null && {
        Clipsend="xsel --clipboard --input"
        Clipreceive="xsel --clipboard --output"
      }
      command -v xclip >/dev/null && {
        Clipsend="xclip -selection clipboard -in"
        Clipreceive="xclip -selection clipboard -out"
      }
      [ -z "$Clipsend" ] && {
        note "Option --clipboard: Need either xclip or xsel
  for clipboard sharing with X server $Xserver.
  Fallback: Disabling option --clipboard."
        check_fallback
        Shareclipboard="no"
      }
      [ -z "$Hostdisplay" ] && {
        note "Option --clipboard: No host display DISPLAY found
  to share clipboard. Fallback: Disabling option --clipboard"
        check_fallback
        Shareclipboard="no"
      }

      echo "#! /usr/bin/env bash
# share clipboard between X servers $Hostdisplay and $Newdisplay

$(declare -f mysleep)
$(declare -f rocknroll)
Timetosaygoodbyefile='$Timetosaygoodbyefile'

while rocknroll ; do
  # read content of clipboard of first X server $Hostdisplay
  X1clip=\"\$(env DISPLAY=$Hostdisplay XAUTHORITY=$Hostxauthority $Clipreceive)\"
  
  # check if clipboard of first X server has changed; if yes, send new content to second X server
  [ \"\$Shareclip\" != \"\$X1clip\" ] && {
    Shareclip=\"\$X1clip\"
    env DISPLAY=$Newdisplay XAUTHORITY=$Xclientcookie $Clipsend <<<  \"\$Shareclip\" 
#    echo \"\$Shareclip\" | env DISPLAY=$Newdisplay XAUTHORITY=$Xclientcookie $Clipsend
  }
  Shareclip=\"\${Shareclip:-' '}\"     # avoid empty string error
  mysleep 0.3                       # sleep a bit to avoid high cpu usage
    
  # read content of clipboard of second X server $Newdisplay
  X2clip=\"\$(env DISPLAY=$Newdisplay XAUTHORITY=$Xclientcookie $Clipreceive)\"
  
  # check if clipboard of second X server has changed; if yes, send new content to first X server
  [ \"\$Shareclip\" != \"\$X2clip\" ] && {
    Shareclip=\"\$X2clip\"
    env DISPLAY=$Hostdisplay XAUTHORITY=$Hostxauthority $Clipsend <<<  \"\$Shareclip\" 
#    echo \"\$Shareclip\" | env DISPLAY=$Hostdisplay XAUTHORITY=$Hostxauthority $Clipsend
  }
  Shareclip=\"\${Shareclip:-' '}\"     # avoid empty string error
  mysleep 0.3                       # sleep a bit to avoid high cpu usage
done
" >> $Clipboardrc
    ;;
  esac
  return 0
}