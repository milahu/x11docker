weston_getoutputname() {        # short startup of weston on tty to grep output name
  unpriv "$Weston --no-config --backend=drm-backend.so >> $Compositorlogfile 2>&1 & echo compositorpid=\$! >>$Storeinfofile"
  waitforlogentry "weston-screencheck" "$Compositorlogfile" "connector" "$Compositorerrorcodes"
  
  grep Output <$Compositorlogfile | grep connector | head -n1 | cut -d ' ' -f3 | rev | cut -c2- | rev
  
  termpid "$(storeinfo dump compositorpid)" weston
  storeinfo drop compositorpid
  mkfile "$Compositorlogfile"
}