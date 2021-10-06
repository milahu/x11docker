create_xdummyxorgconf() {       # options --xdummy, --xpra: create xorg.conf for Xdummy
  local Modelinefile
  echo '# This xorg configuration file is forked and changed from xpra to start a dummy X11 server.
# For original and details, please see: https://xpra.org/Xdummy.html
# Set of modelines for different resolutions is created in xinitrc.
Section "ServerFlags"
  Option "DontVTSwitch" "true"
  Option "AllowMouseOpenFail" "true"
  Option "PciForceNone" "true"
  Option "AutoEnableDevices" "false"
  Option "AutoAddDevices" "false"
EndSection
Section "Device"
  Identifier "dummy_videocard"
  Driver "dummy"
  DacSpeed 600
  Option "ConstantDPI" "true"
  VideoRam '$(($Maxxaxis * $Maxyaxis * 2 * 32 / 8 / 1024))'
EndSection
Section "Monitor"
  Identifier "dummy_monitor"
  HorizSync   1.0 - 2000.0
  VertRefresh 1.0 - 200.0
' >> $Xdummyconf
  # Modeline for desired virtual screen size
  echo "Modeline $Modeline" >> $Xdummyconf
  # Subset of smaller Modelines
  Modelinefile="$(create_modelinefile "${Maxxaxis}x${Maxyaxis}")"
  cat "$Modelinefile" >> $Xdummyconf
  echo '
EndSection
Section "Screen"
  Identifier "dummy_screen"
  Device "dummy_videocard"
  Monitor "dummy_monitor"
  DefaultDepth 24
  SubSection "Display"
    Viewport 0 0
    Depth 32
    Modes '$(echo $Modeline | cut -d " " -f1)'
    Virtual '$Xaxis' '$Yaxis'
  EndSubSection
EndSection
Section "ServerLayout"
  Identifier   "dummy_layout"
  Screen       "dummy_screen"
EndSection
' >> $Xdummyconf
}