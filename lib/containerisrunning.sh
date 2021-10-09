containerisrunning() {          # check if container is running
  storeinfo test containerid || return 1
  case $Mobyvm in
    no)   checkpid      "$(storeinfo dump pid1pid)" ;;
    yes)  $Containerbackendbin inspect "$(storeinfo dump containerid)" >/dev/null 2>&1 ;;
  esac
}