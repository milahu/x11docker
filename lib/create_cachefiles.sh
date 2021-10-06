create_cachefiles() {           # create empty cache files owned by unprivileged user
  local Line
  # create base cache folder
  [ "$Cachebasefolder" ] || {
    #Cachebasefolder="$Hostuserhome/.cache/x11docker"    ### FIXME really a good idea for MS Windows? WSL cache provides performance, but maybe must not be shared with container to avoid file access errors.
    case $Winsubsystem in
      ""|MSYS2|CYGWIN) Cachebasefolder="$Hostuserhome/.cache/x11docker" ;;
      WSL1|WSL2)
        case $Mobyvm in
          yes)
            Cachebasefolder="$(convertpath subsystem "$(wincmd "echo %userprofile%")")/x11docker/cache"
            mkdir -p "$Hostuserhome/.cache/x11docker/symlink"
            [ -e "$Hostuserhome/.cache/x11docker/symlink" ] || ln -s -T "$Cachebasefolder" "$Hostuserhome/.cache/x11docker/symlink"
            mkfile "$Hostuserhome/.cache/x11docker/symlink/symlink.txt"
            echo "x11docker: With MobyVM x11docker cache in WSL is stored in 
$Cachebasefolder
to allow file sharing with containers.
A symbolic link is created in WSL at
$Hostuserhome/.cache/x11docker/symlink
" >> "$Hostuserhome/.cache/x11docker/symlink/symlink.txt"
          ;;
          no)
            Cachebasefolder="$Hostuserhome/.cache/x11docker" 
          ;;
        esac
      ;;
    esac
  }
  [ "$Cachebasefolder" = "/x11docker/cache" ] && error "Failed to find a valid path for cache directory.
  Please report at https://github.com/mviereck/x11docker
  As a workaround you can specify a cache folder with --cachebasedir DIR."
  
  Cachebasefolder="$(convertpath subsystem "$Cachebasefolder")"
  [ "$Cachebasefolder" != "$(echo $Cachebasefolder | sed -e 's/ *//g')" ] && error "Cache root folder must not contain whitespaces.
  $Cachebasefolder"
  unpriv "mkdir -p $Cachebasefolder"                                      || error "Could not create cache folder
  $Cachebasefolder"
  writeaccess $Hostuseruid $Cachebasefolder                               || error "User $Hostuser does not have write access to cache folder
  $Cachebasefolder"
  
  # Create cache subfolders
  Cachefolder="$Cachebasefolder/$Codename-$Cachenumber"
  [ -d "$Cachefolder" ] && error "Cache folder already exists:
  $Cachefolder"

  [ "$Cachefolder" != "$(escapestring "$Cachefolder")" ] && error "Invalid name created for cache folder:
    $Cachefolder
  Most probably provided image name (or --exe command) is invalid in some way:
    $(escapestring "$Imagename")
  For special setups like command chains use a syntax like:
    x11docker IMAGENAME  --  sh -c \"cd /etc && xterm\""

  Sharefolder="$Cachefolder/$Sharefolder"
  unpriv "mkdir -p $Sharefolder"
  
  # Files in $Cachefolder: host only access
  Compositorlogfile="$Cachefolder/$Compositorlogfile"               && mkfile $Compositorlogfile
  Dockercommandfile="$Cachefolder/$Dockercommandfile"               && mkfile $Dockercommandfile
  Dockerinfofile="$Cachefolder/$Dockerinfofile"                     && mkfile $Dockerinfofile
  Dockerrc="$Cachefolder/$Dockerrc"                                 && mkfile $Dockerrc
  Dockerstopsignalfifo="$Cachefolder/$Dockerstopsignalfifo"
  Hostxauthority="$Cachefolder/$Hostxauthority"                     && mkfile $Hostxauthority
  Messagelogfile="$Cachefolder/$Messagelogfile"                     && mkfile $Messagelogfile
  Nxagentclientrc="$Cachefolder/$Nxagentclientrc"                   && mkfile $Nxagentclientrc
  Nxagentkeysfile="$Cachefolder/$Nxagentkeysfile"                   && mkfile $Nxagentkeysfile
  Nxagentoptionsfile="$Cachefolder/$Nxagentoptionsfile"             && mkfile $Nxagentoptionsfile
  Pulseaudioconf="$Cachefolder/$Pulseaudioconf"                     && mkfile $Pulseaudioconf
  Clipboardrc="$Cachefolder/$Clipboardrc"                           && mkfile $Clipboardrc
  Storepidfile="$Cachefolder/$Storepidfile"                         && mkfile $Storepidfile
  Systemdconsoleservice=$Cachefolder/$Systemdconsoleservice         && mkfile $Systemdconsoleservice
  Systemdenvironment=$Cachefolder/$Systemdenvironment               && mkfile $Systemdenvironment
  Systemdjournallogfile=$Sharefolder/$Systemdjournallogfile         && mkfile $Systemdjournallogfile
  Systemdjournalservice=$Cachefolder/$Systemdjournalservice         && mkfile $Systemdjournalservice
  Systemdtarget=$Cachefolder/$Systemdtarget                         && mkfile $Systemdtarget
  Systemdwatchservice=$Cachefolder/$Systemdwatchservice             && mkfile $Systemdwatchservice
  Watchpidfifo="$Cachefolder/$Watchpidfifo"
  Westonini="$Cachefolder/$Westonini"                               && mkfile $Westonini
  Xdummyconf="$Cachefolder/$Xdummyconf"                             && mkfile $Xdummyconf
  Xinitlogfile="$Cachefolder/$Xinitlogfile"                         && mkfile $Xinitlogfile
  Xinitrc="$Cachefolder/$Xinitrc"                                   && mkfile $Xinitrc
  Xkbkeymapfile="$Cachefolder/$Xkbkeymapfile"                       && mkfile $Xkbkeymapfile
  Xorgwrapper="$Cachefolder/$Xorgwrapper"                           && mkfile $Xorgwrapper
  Xpraclientlogfile="$Cachefolder/$Xpraclientlogfile"               && mkfile $Xpraclientlogfile
  Xpraserverlogfile="$Cachefolder/$Xpraserverlogfile"               && mkfile $Xpraserverlogfile
  Xservercookie="$Cachefolder/$Xservercookie"                       && mkfile $Xservercookie
  Xtermrc="$Cachefolder/$Xtermrc"                                   && mkfile $Xtermrc
  
  # Files in $Sharefolder: shared to /x11docker in container
  Cmdrc="$Sharefolder/$Cmdrc"                                       && mkfile $Cmdrc
  Cmdstderrlogfile="$Sharefolder/$Cmdstderrlogfile"                 && mkfile $Cmdstderrlogfile 666
  Cmdstdinfifo="$Sharefolder/$Cmdstdinfifo"
  Cmdstdoutlogfile="$Sharefolder/$Cmdstdoutlogfile"                 && mkfile $Cmdstdoutlogfile 666
  Containerrc="$Sharefolder/$Containerrc"                           && mkfile $Containerrc
  Containerenvironmentfile="$Sharefolder/$Containerenvironmentfile" && mkfile $Containerenvironmentfile 666
  Containerlocaltimefile="$Sharefolder/$Containerlocaltimefile"
  Containerlogfile="$Sharefolder/$Containerlogfile"                 && mkfile $Containerlogfile 666
  Containerrootrc="$Sharefolder/$Containerrootrc"                   && mkfile $Containerrootrc
  Logfile="$Sharefolder/x11docker.log"                              && mkfile $Logfile 666
  Messagefifo="$Sharefolder/$Messagefifo"
  Pulseaudiocookie="$Sharefolder/$Pulseaudiocookie"
  Pulseaudiosocket="$Sharefolder/$Pulseaudiosocket"
  Storeinfofile="$Sharefolder/$Storeinfofile"                       && mkfile $Storeinfofile 666
  Timetosaygoodbyefile="$Sharefolder/$Timetosaygoodbyefile"         && mkfile $Timetosaygoodbyefile
  Timetosaygoodbyefifo="$Sharefolder/$Timetosaygoodbyefifo"
  Xclientcookie="$Sharefolder/$Xclientcookie"                       && mkfile $Xclientcookie
  
  # Files in $Cachebasefolder
  Dockerimagelistfile="$Cachebasefolder/$Dockerimagelistfile"       && mkfile $Dockerimagelistfile
  Logfilebackup="$Cachebasefolder/x11docker.log"
  Modelinefilebasepath="$Cachebasefolder/$Modelinefilebasepath"
  
  # file to store display numbers in use today
  Numbersinusefile="$Cachebasefolder/$Numbersinusefile"
  for Line in $(find $Cachebasefolder/displaynumbers.* 2>/dev/null ||:) ; do
    [ "$Line" != "$Numbersinusefile" ] && rm "$Line"
  done
  [ -e "$Numbersinusefile" ] || mkfile "$Numbersinusefile"
  
  # libc timezone file
  [ -e "$Hostlocaltimefile" ] && cp "$Hostlocaltimefile" "$Containerlocaltimefile"
  
  storeinfo "cache=$Cachefolder"
  storeinfo "stdout=$Cmdstdoutlogfile"
  storeinfo "stderr=$Cmdstderrlogfile"
  
  return 0
}