store_runoption() {             # store env, cap or volume/device for docker command
  # $1  env     store environment variable $2
  #     volume  store volume or device path $2
  #     cap     store capability $2
  #     dump    dump all entries of $2
  local Count Line Path Readwritemode
  case ${1:-} in
    env)
      Containerenvironmentcount="$((Containerenvironmentcount + 1))"
      Containerenvironment[$Containerenvironmentcount]="${2:-}"
    ;;
    volume)
      Path="$(convertpath subsystem "${2:-}")"
      Readwritemode="$(echo "${2:-}" | rev | cut -c1-3 | rev)"
      [ "$Readwritemode" = ":ro" ] || Readwritemode=""
      case "${Path:0:1}" in
        "/")
          [ -e "$Path" ] && {
            Sharevolumescount="$((Sharevolumescount + 1))"
            Sharevolumes[$Sharevolumescount]="${2:-}"
            [ -h "$Path" ] && myrealpath "$Path" >/dev/null && {
              note "Option --share: Shared file is a symbolic link. Sharing target, too.
  Symlink: $Path
  Target:  $(myrealpath "$Path")"
              store_runoption volume "$(myrealpath "$Path")$Readwritemode"
            }
          } 
          [ -e "$Path" ] || error "Option --share: Path not found:
  $Path"
        ;;
        *)
          grep -q '/' <<< "$Path" && error "Option --share: Invalid argument $Path.
  Either specify an absolute path beginning with '/'
  or specify a docker volume without any '/'."
          Sharevolumescount="$((Sharevolumescount + 1))"
          Sharevolumes[$Sharevolumescount]="${2:-}"
        ;;
      esac
      [ -z "$Path" ] && error "Option --share needs an argument"
    ;;
    cap)
      for Line in ${2:-} ; do
        Capabilities="$Capabilities
$Line"
      done
    ;;
    dump)
      case ${2:-} in
        env) for ((Count=$Containerenvironmentcount ; Count>=1 ; Count --)) ; do echo "${Containerenvironment[$Count]}" ; done ;;
        volume) for ((Count=1 ; Count<=$Sharevolumescount ; Count ++))      ; do echo "${Sharevolumes[$Count]}" ; done ;;
        cap)
          while read Line; do
            [ "$Line" ] && case $Capdropall in
              yes) echo "$Line" ;;
              no)  grep -w -q "$Line" <<< "SETPCAP MKNOD AUDIT_WRITE CHOWN NET_RAW DAC_OVERRIDE FOWNER FSETID KILL SETGID SETUID NET_BIND_SERVICE SYS_CHROOT SETFCAP" || echo "$Line" ;;
            esac
          done < <(echo "$Capabilities" | sort -u)
        ;;
      esac
    ;;
  esac
  return 0
}