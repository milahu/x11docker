cleanup() {                     # --cleanup : check for non-removed containers and left cache files
  # Cleans x11docker cache and removes running and stopped x11docker containers.
  # Does not change --home folders.
  local Orphanedcontainers= Orphanedfolders= Line= Inspect Containerid

  note "x11docker will check for orphaned containers from earlier sessions.
  This can happen if docker was not closed successfully.
  x11docker will look for those containers and will clean up x11docker cache.
  Caution: any currently running x11docker sessions will be terminated, too."

  cd $Cachebasefolder || error "Could not cd to cache folder '$Cachebasefolder'."

  grep -q .cache/x11docker <<<$Cachebasefolder && Orphanedfolders="$(find "$Cachebasefolder" -mindepth 1 -maxdepth 1 -type d | sed s%$Cachebasefolder/%% | grep -w -v x11docker-gui)"
  # e X11DOCKER_LASTCLEANFOLDER may be set by x11docker-gui to spare its cache folder.
  [ "${X11DOCKER_LASTCLEANFOLDER:-}" ] && Orphanedfolders="$(echo "$Orphanedfolders" | grep -v $X11DOCKER_LASTCLEANFOLDER)"
  Orphanedcontainers="$($Containerbackendbin ps -a | grep x11docker_X | rev | cut -d' ' -f1 | rev)"
  Orphanedcontainers="$Orphanedcontainers $(find "$Cachebasefolder" -mindepth 2 -maxdepth 2 -type f -name 'container.id' -exec cat {} \;)"
  Orphanedcontainers="$(env IFS='' echo $Orphanedcontainers)"

  # check for double entrys name/id, check for already non-existing containers
  for Line in $Orphanedcontainers; do
    Inspect="$($Containerbackendbin inspect $Line 2>/dev/null)"
    [ -n "$Inspect" ] && {
      Containerid="$(parse_inspect "$Inspect" "Id")"
      Orphanedcontainers="$(sed "s%$Line%$Containerid%" <<< "$Orphanedcontainers")"
      :
    } || Orphanedcontainers="$(sed s/$Line// <<< $Orphanedcontainers)"
  done
  Orphanedcontainers="$(sort <<< "$Orphanedcontainers" | uniq)"

  [ -z "$Orphanedcontainers$Orphanedfolders" ] && {
    note "No orphaned containers or cache files found. good luck!"
  } || {
    note "Found orphaned containers:
$Orphanedcontainers"
    note "Found orphaned folders in $Cachebasefolder:
$Orphanedfolders"

    for Line in $Orphanedfolders ; do
      [ -d "$Cachebasefolder/$Line/share" ] && [ ! -s "$Cachebasefolder/$Line/share/timetosaygoodbye" ] && {
        note "Found possibly active container for cache dir $Line.
  Will summon it to terminate itself."
        echo timetosaygoodbye >> "$Cachebasefolder/$Line/share/timetosaygoodbye"
      }
    done
    [ -n "$Orphanedfolders" ] && sleep 3

    [ -n "$Orphanedcontainers" ] && {
      note "Removing containers with: $Containerbackendbin rm -f $Orphanedcontainers"
      bash -c "$Containerbackendbin rm -f $Orphanedcontainers" 2>&1
    }
    [ -n "$Orphanedfolders" ] && {
      note "Removing cache files with: rm -R -f $Orphanedfolders"
      rm -R -f $Orphanedfolders 2>&1
    }
  }

  [ "${X11DOCKER_LASTCLEANFOLDER:-}" ] && {
    echo timetosaygoodbye >>$X11DOCKER_LASTCLEANFOLDER/share/timetosaygoodbye
    echo timetosaygoodbye >>$X11DOCKER_LASTCLEANFOLDER/share/timetosaygoodbye.fifo
    sleep 2
  }

  Logfile=

  note "Removing remaining files with: rm -Rf -v $Cachebasefolder/*"
  rm -Rf -v $Cachebasefolder/*

  note "Removing cache base folder with: rmdir -v $Cachebasefolder"
  cd
  [ "$(basename $Cachebasefolder)" = x11docker ] && rmdir -v $Cachebasefolder  || warning "Did not succeed in removing cache folder
  $Cachebasefolder
  Please run 'x11docker --cleanup' as root."

  $Containerbackendbin info >/dev/null 2>/dev/null || warning "Could not check for docker images.
  Please run 'x11docker --cleanup' as root
  to make sure that no orphaned containers are left."

  note "Cleanup ready."
}