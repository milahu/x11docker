create_containerrootrc() {      ### create containerrootrc: This script runs as root in container
  local Line=

  echo "#! /bin/sh"
  echo ""
  echo "# containerrootrc"
  echo "# This Script is executed as root in container."
  echo "# - Create container user"
  echo "# - Time zone"
  echo "# - Install NVIDIA driver if requested"
  echo "# - Set up init system services and DBus for --init=systemd|openrc|runit|sysvinit"
  echo ""
#  echo "set -x"
    
  echo "# redirect output to have it available before 'docker logs' starts. --init=runit (void) would eat up the output at all for unknown reasons."
  echo "exec 1>>$(convertpath share $Containerlogfile) 2>&1"
  echo ""
  
  declare -f storeinfo
  declare -f rocknroll
  echo "$Messagefifofuncs"
  echo "Messagefile=$(convertpath share $Messagefifo)"
  echo "Storeinfofile='$(convertpath share $Storeinfofile)'"
  echo "Timetosaygoodbyefile=$(convertpath share $Timetosaygoodbyefile)"
  echo ""

  echo "debugnote 'Running containerrootrc: Setup as root in container'"
  echo ""
  
  echo "Error=''"
  echo "for Line in cat chmod chown cut cd cp date echo env export grep id ln ls mkdir mv printf rm sed sh sleep tail touch; do"
  echo "  command -v \"\$Line\" || {"
  echo "    warning \"ERROR: Command not found in image: \$Line\""
  echo "    Error=1"
  echo "  }"
  echo "done"
  echo "[ \"\$Error\" ] && error 'Commands for container setup missing in image.
  You can try with option --no-setup to avoid this error.'"
  echo ""

  echo "# Check type of libc"
  echo "ldd --version 2>&1 | grep -q 'musl libc' && Containerlibc='musl'"
  echo "ldd --version 2>&1 | grep -q -E 'GLIBC|GNU libc'  && Containerlibc='glibc'"
  echo 'debugnote "containerrootrc: Container libc: $Containerlibc"'
  echo ""

  echo "# Prepare X environment"
  echo "# Create some system dirs with needed permissions"
  echo "mkdir -v -p /var/lib/dbus /var/run/dbus"
  echo "mkdir -v -p -m 1777 /tmp/.ICE-unix /tmp/.X11-unix /tmp/.font-unix"
  echo "chmod -c 1777 /tmp/.ICE-unix /tmp/.X11-unix /tmp/.font-unix"
  echo "export DISPLAY=$Newdisplay XAUTHORITY=$(convertpath share $Xclientcookie)"
  [ "$Xoverip" = "no" ] && {
    echo "[ -e /X$Newdisplaynumber ] && ln -s /X$Newdisplaynumber $Newxsocket" # done again in containerrc. At least x11docker/deepin needs it here already.
    echo "ls -l /X$Newdisplaynumber"
    echo "ls -l $Newxsocket"
  }
  echo ""
  
  [ "$Screensize" ] && {
    echo "# workaround: autostart of xrandr for some desktops like deepin, cinnamon and gnome to fix wrong autoresize"
    echo "echo '#! /bin/sh
Output=\$(xrandr | grep ' connected' | cut -d\" \" -f1)
Mode=$Screensize
xrandr --output \$Output --mode \$Mode\n\
' > /usr/local/bin/x11docker-xrandr"
    echo "chmod +x /usr/local/bin/x11docker-xrandr"
    echo "mkdir -p /etc/xdg/autostart"
    echo "echo '[Desktop Entry]
Encoding=UTF-8
Version=0.9.4
Type=Application
Name=x11docker-xrandr
Comment=
Exec=/usr/local/bin/x11docker-xrandr
' > /etc/xdg/autostart/x11docker-xrandr.desktop"
  }
  echo ""


  echo "# Time zone"
  [ "$Hostlocaltimefile" ] && {
    echo '[ ! -d /usr/share/zoneinfo ] && [ "$Containerlibc" = "'$Hostlibc'" ] && {'
    echo "  mkdir -p $(dirname $Hostlocaltimefile)"
    echo "  cp '$(convertpath share $Containerlocaltimefile)' '$Hostlocaltimefile'"
    echo "}"
    echo "[ -e '$Hostlocaltimefile' ] && ln -f -s '$Hostlocaltimefile' /etc/localtime"
    echo ""
  }

  echo "# Container system"
  echo "Containersystem=\"\$(grep '^ID=' /etc/os-release 2>/dev/null | cut -d= -f2 || echo 'unknown')\""
  echo "verbose \"Container system ID: \$Containersystem\""
  echo ""

  echo "# Environment variables"
  while read -r Line; do
    echo "export '$Line'"
  done < <(store_runoption dump env)
  echo ""

  echo "# Check container user"
  echo "Containeruser=\"\$(storeinfo dump containeruser)\""
  echo "Containeruser=\"\${Containeruser:-$Containeruser}\""
  echo ""
  case $Createcontaineruser in
    yes)
      echo "Containeruserhome='$Containeruserhome'"
      
      # create container user
      echo "# Create user entry in /etc/passwd (and delete possibly existing same uid)"
      echo "cat /etc/passwd | grep -v ':$Containeruseruid:' > /tmp/passwd"             ### FIXME gids same as uid would be deleted, too
      echo ""
      echo "# Disable possible /etc/shadow passwords for other users"
      echo "sed -i 's%:x:%:-:%' /tmp/passwd"
      case $Containerusershell in
        auto) echo "bash --version >/dev/null 2>&1 && Containerusershell=/bin/bash || Containerusershell=/bin/sh" ;;
        *)    echo "Containerusershell='$Containerusershell'" ;;
      esac
      echo "Containeruserentry=\"$Containeruser:x:$Containeruseruid:$Containerusergid:$Containeruser,,,:$Containeruserhome:\$Containerusershell\""
      echo 'debugnote "containerrootrc: $Containeruserentry"'
      echo 'echo "$Containeruserentry" >> /tmp/passwd'
      echo ""
      echo "rm /etc/passwd"
      echo "mv /tmp/passwd /etc/passwd || warning 'Unable to change /etc/passwd. That may be a security risk.'"
      echo ""
      echo "# Create password entry for container user in /etc/shadow"
      echo "rm -v /etc/shadow || warning 'Cannot change /etc/shadow. That may be a security risk.'"
      echo "echo \"$Containeruser:$Containeruserpassword:17293:0:99999:7:::\" > /etc/shadow"
      case $Sudouser in
        "")  echo "echo 'root:*:17219:0:99999:7:::' >> /etc/shadow" ;;
        *)   echo "echo 'root:$Containeruserpassword:17219:0:99999:7:::' >> /etc/shadow  # with option --sudouser, set root password 'x11docker'"
             echo "sed -i 's%root:-:%root:x:%' /etc/passwd                               # allow password in /etc/shadow"
        ;;
      esac
      echo "chmod 640 /etc/shadow   # can fail depending on available capabilities" 
      echo ""
      echo "# Create user group entry (and delete possibly existing same gid)"
      echo "cat /etc/group | grep -v ':$Containerusergid:'    > /tmp/group"
      echo "echo \"$Containerusergroup:x:$Containerusergid:\" >> /tmp/group"
      echo "mv /tmp/group /etc/group"
      echo ""
      
      # sudo configuration
      echo "# Create /etc/sudoers, delete /etc/sudoers.d. Overwrite possible sudo setups in image."
      echo "[ -e /etc/sudoers.d ] && rm -v -R /etc/sudoers.d"
      echo "[ -e /etc/sudoers ]   && rm -v /etc/sudoers"
      echo "echo '# /etc/sudoers created by x11docker' > /etc/sudoers"
      echo "echo 'Defaults	env_reset'                >> /etc/sudoers"
      echo "echo 'root ALL=(ALL) ALL'                 >> /etc/sudoers"
      case $Sudouser in
        yes)      echo "echo '$Containeruser ALL=(ALL) ALL' >> /etc/sudoers" ;;
        nopasswd) echo "echo '$Containeruser ALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers" ;;
      esac
      echo ""

      # try to disable possible custom PAM setups that could allow switch to root in container
      [ -z "$Sudouser" ] && {
        echo "# Restrict PAM configuration of su and sudo"
        echo "mkdir -p /etc/pam.d"
        echo "[ -e /etc/pam.d/sudo ] && rm -v /etc/pam.d/sudo"
        echo 'case "$Containersystem" in'
        echo '  fedora)'
        echo "    echo '#%PAM-1.0' > /etc/pam.d/su"
        echo "    echo 'auth     sufficient pam_rootok.so'  >> /etc/pam.d/su"
        #echo "    echo 'auth     substack system-auth'      >> /etc/pam.d/su"
        #echo "    echo 'auth     include postlogin'         >> /etc/pam.d/su"
        echo "    echo 'account  sufficient pam_succeed_if.so uid = 0 use_uid quiet'  >> /etc/pam.d/su"
        #echo "    echo 'account  include system-auth'       >> /etc/pam.d/su"
        #echo "    echo 'password include system-auth'       >> /etc/pam.d/su"
        echo "    echo 'session  include system-auth'       >> /etc/pam.d/su"
        #echo "    echo 'session  include  postlogin'        >> /etc/pam.d/su"
        #echo "    echo 'session  optional pam_xauth.so'     >> /etc/pam.d/su"
        echo '  ;;'
        echo '  *)'
        echo "    echo '#%PAM-1.0' > /etc/pam.d/su"
        echo "    echo 'auth sufficient pam_rootok.so' >> /etc/pam.d/su  # allow root to switch user without a password"
        echo "    echo '@include common-auth'          >> /etc/pam.d/su"
        echo "    echo '@include common-account'       >> /etc/pam.d/su"
        echo "    echo '@include common-session'       >> /etc/pam.d/su"
        echo '  ;;'
        echo 'esac'
        echo ""
      }
    ;;
    no)
      # check container user home. Can miss with --user=RETAIN
      echo "Containeruserhome=\"\$(cat /etc/passwd | grep '\$Containeruser:.:' | cut -d: -f6)\""
      echo "Containeruserhome=\"\${Containeruserhome:-/tmp/\$Containeruser}\""
      echo ""
      echo "debugnote \"containerrootrc: Container user: \$(id \$Containeruser)
\$(cat /etc/passwd | grep '\$Containeruser:.:')\""
      echo ""
    ;;
  esac
  
  # /etc/group
  echo "# Set up container user groups"
  for Line in $Containerusergroups ; do
    echo "Groupname=\"$(cat /etc/group 2>/dev/null | grep "$Line" | cut -d: -f1)\""
    echo "Groupid=\"$(cat /etc/group   2>/dev/null | grep "$Line" | cut -d: -f3)\""
    echo "[ \"\$Groupname\" ] || Groupname=\"\$(cat /etc/group | grep \"$Line\" | cut -d: -f1)\""
    echo "[ \"\$Groupid\" ]   || Groupid=\"\$(cat /etc/group | grep \"$Line\" | cut -d: -f3)\""
    echo "[ \"\$Groupname\" ] && {"
    echo "  cat /etc/group | sed \"s/^\$Groupname.*/\$Groupname:x:\$Groupid:\$(cat /etc/group | grep \"\$Groupname:.:\" | cut -d: -f4 ),\$Containeruser/\" | sed 's/:,/:/' > /tmp/group"
    echo "  cat /etc/group | grep -q \"\$Groupname:.:\" || echo \"\$Groupname:x:\$Groupid:\$Containeruser\" >> /tmp/group"
    echo "  cp /tmp/group /etc/group"
    echo "} || note 'Failed to add container user to group $Line.'"
    echo ""
  done

  # HOME
  echo "# Create HOME"
  echo '[ -e "$Containeruserhome" ] || {'
  echo '  mkdir -v -p "$(dirname "$Containeruserhome")"'
  echo '  mkdir -v -m 777 "$Containeruserhome"'
  echo '  chown -v "$Containeruser":"$Containerusergroup" "$Containeruserhome" && chmod -v 755 "$Containeruserhome"  # can fail depending on capabilities'
  echo '}'
  #echo "chown \$Containeruser:\$(id -g \$Containeruser) \"\$Containeruserhome\""
  echo "ls -la \$Containeruserhome"
  echo ""

  # --gpu with closed source nvidia driver
  [ "$Nvidiainstallerfile" ] && {
    echo "# Install NVIDIA driver"
    echo "Nvidiaversion=\"\$(nvidia-settings -v 2>/dev/null | grep version | rev | cut -d' ' -f1 | rev)\""
    echo '[ "$Nvidiaversion" ] && note "Found NVIDIA driver $Nvidiaversion in image."'
    echo 'case "$Nvidiaversion" in'
    echo "  $Nvidiaversion) note 'NVIDIA driver version in image matches version on host. Skipping installation.' ;;"
    echo "  *)"
    echo "    Installationwillsucceed=maybe"
    echo '    case "$Containerlibc" in'
    echo "      musl) note 'Installing NVIDIA driver in container systems
  based on musl libc like Alpine is not possible due to
  proprietary closed source policy of NVIDIA corporation.'"
    echo "        Installationwillsucceed=no"
    echo "      ;;"
    echo "    esac"
    echo "    case \$Containersystem in"
    echo "      opensuse)"
    echo "        note \"Nvidia driver installation probably fails in \$Containersystem.
  You can try to install nvidia driver $Nvidiaversion in image yourself.\""
    echo "      ;;"
    echo "    esac"
    echo "    [ \"\$Installationwillsucceed\" = \"maybe\" ] && {"
    echo "      note 'Installing NVIDIA driver $Nvidiaversion in container.'"
    echo "      mkdir -m 1777 /tmp2"
    echo "      # provide fake tools to fool installer dependency check"
    echo "      ln -s /bin/true /tmp2/modprobe"
    echo "      ln -s /bin/true /tmp2/depmod"
    echo "      ln -s /bin/true /tmp2/lsmod"
    echo "      ln -s /bin/true /tmp2/rmmod"
    echo "      ln -s /bin/true /tmp2/ld"
    echo "      ln -s /bin/true /tmp2/objcopy"
    echo "      ln -s /bin/true /tmp2/insmod"
    echo "      Nvidiaoptions='--accept-license --no-runlevel-check --no-questions --no-backup --ui=none --no-kernel-module --no-nouveau-check'"
    echo "      env TMPDIR=/tmp2 PATH=\"/tmp2:\$PATH\" sh $Nvidiacontainerfile -A | grep -q -- '--install-libglvnd'        && Nvidiaoptions=\"\$Nvidiaoptions --install-libglvnd\""
    echo "      env TMPDIR=/tmp2 PATH=\"/tmp2:\$PATH\" sh $Nvidiacontainerfile -A | grep -q -- '--no-nvidia-modprobe'      && Nvidiaoptions=\"\$Nvidiaoptions --no-nvidia-modprobe\""
    echo "      env TMPDIR=/tmp2 PATH=\"/tmp2:\$PATH\" sh $Nvidiacontainerfile -A | grep -q -- '--no-kernel-module-source' && Nvidiaoptions=\"\$Nvidiaoptions --no-kernel-module-source\""
    echo "      env TMPDIR=/tmp2 PATH=\"/tmp2:\$PATH\" sh $Nvidiacontainerfile --tmpdir /tmp2 \$Nvidiaoptions || note 'ERROR: Installation of NVIDIA driver failed.
  Run with option --verbose to see installer output.'"
    echo "      rm -R /tmp2 && unset TMPDIR"
    echo "    } || note 'Skipping installation of $Nvidiacontainerfile'"
    echo "  ;;"
    echo "esac"
    echo ""
  }
  
  echo "rocknroll || exit 64"
  echo ""
  
  [ "$Switchcontaineruser" = "yes" ] && {
    echo "# Create some helper scripts"

    echo "mkdir -p /usr/local/bin"
    echo ""
    
    echo "echo \"#! /bin/sh
# Send messages to x11docker on host.
# To be sourced by other scripts.
$Messagefifofuncs_escaped
Messagefile=$(convertpath share $Messagefifo)
\" >/usr/local/bin/x11docker-message"
    echo ""
    
    echo "echo \"#! /bin/sh
# User switch from root in containerrootrc to unprivileged user in containerrc.
# Additionally, su triggers logind and elogind. (Except su from busybox?)
# Called by x11docker-agetty.
. /usr/local/bin/x11docker-message
debugnote 'Running x11docker-login'
chmod +x $(convertpath share $Containerrc)
exec su - -s /bin/sh  \$Containeruser $(convertpath share $Containerrc)
\" >/usr/local/bin/x11docker-login"
    echo "chmod +x /usr/local/bin/x11docker-login"
    echo ""
    
    echo "echo \"#! /bin/sh
# Run agetty to get a valid console.
# Needed at least for --interactive. 
# Runs x11docker-login.
# Called at different places depending on init system.
. /usr/local/bin/x11docker-message
debugnote 'Running x11docker-agetty'
[ -e /sbin/agetty ] && exec agetty -a \$Containeruser -l /usr/local/bin/x11docker-login console
debugnote 'x11docker-agetty: agetty not found.'
[ '$Interactive' = 'yes' ] && note '/sbin/agetty not found. --interactive can fail.
  Please install package util-linux in image.'
exec /usr/local/bin/x11docker-login
\" >/usr/local/bin/x11docker-agetty"
    echo "chmod +x /usr/local/bin/x11docker-agetty"
    echo ""

    echo "echo \"#! /bin/sh
# Wait for end of x11docker and shut down container. 
# Started in background by x11docker for sysvinit|runit|openrc.
. /usr/local/bin/x11docker-message
debugnote 'Running x11docker-watch'
read Dummy <$(convertpath share $Timetosaygoodbyefifo)
echo timetosaygoodbye >>$(convertpath share $Timetosaygoodbyefifo)
debugnote 'x11docker-watch: $Initsystem shutdown now'
shutdown 0
systemctl poweroff
openrc-shutdown --poweroff 0
halt
halt -f
\" >/usr/local/bin/x11docker-watch"
    echo "chmod +x /usr/local/bin/x11docker-watch"
    echo ""
  }
  
  case $Initsystem in
    tini|none|dockerinit) ;;
    systemd)
      echo "# --init=systemd"
      echo "# enable x11docker CMD service"
      echo "systemctl unmask console-getty.service"
      echo "systemctl enable console-getty.service"
      echo "systemctl enable x11docker-journal.service"
      echo ""
      echo "systemctl unmask systemd-logind"
      echo "systemctl enable systemd-logind"
      echo ""
      echo "# remove failing and annoying services"
      echo "Unservicelist='
              apt-daily.service
              apt-daily.timer
              apt-daily-upgrade.service
              apt-daily-upgrade.timer
              bluetooth.service
              cgproxy.service
              deepin-anything-monitor.service
              deepin-sync-daemon.service
              display-manager.service
              fprintd.service
              gdm3.service
              gvfs-udisks2-volume-monitor.service
              hwclock_stop.service
              lastore-daemon.service
              lastore-update-metadata-info.service
              lightdm.service
              NetworkManager.service
              plymouth-quit.service
              plymouth-quit-wait.service
              plymouth-read-write.service
              plymouth-start.service
              rtkit-daemon.service
              sddm.service
              systemd-localed.service
              systemd-hostnamed.service
              tracker-extract.service
              tracker-miner-fs.service
              tracker-store.service
              tracker-writeback.service
              udisks2.service
              upower.service
              '"
      echo "for Service in \$(find /lib/systemd/system/* /usr/lib/systemd/user/* /etc/systemd/system/* /etc/systemd/user/*) ; do"
      echo '  echo "$Unservicelist" | grep -q "$(basename $Service)" && {'
      echo '    debugnote "--init=systemd: Removing $Service"'
      echo '    rm $Service'
      echo '  }'
      echo "done"
      echo "# Fix for Gnome 3"
      echo 'sed -i "s/ProtectHostname=yes/ProtectHostname=no/" /lib/systemd/system/systemd-logind.service'
    ;;
    runit)
      echo "# --init=runit"
      echo "# create and enable x11docker service containing container command"
      echo "mkdir -p /etc/sv/x11docker"
      echo "mkdir -p /etc/runit/runsvdir/default"
      echo "mkdir -p /etc/runit/1.d"
      echo "mkdir -p /service"
      echo ""
      echo "echo \"#! /bin/sh
$(declare -f mysleep)
waitforservice() {
  Service=\\\$1
  [ \\\"\\\$(sv check \\\$Service | cut -d: -f1)\\\" = 'ok' ] && {
    echo \"x11docker: waiting for service \\\$Service ...\"
    for Count in $(seq -s' ' 20); do
      [ \\\"\\\$(sv status \\\$Service | cut -d: -f1)\\\" = 'down' ] && mysleep 0.2 || break
    done
  }
}