writeaccess() {                 # check if useruid $1 has write access to folder $2
  local dirVals= gMember= IFS=
  IFS=$'\t' read -a dirVals < <(stat -Lc "%U	%G	%A" "${2:-}")
  [ "$(id -u $dirVals)" == "${1:-}" ] && [ "${dirVals[2]:2:1}" == "w" ]   && return 0
  [ "${dirVals[2]:8:1}" == "w" ]                                          && return 0
  [ "${dirVals[2]:5:1}" == "w" ] && {
    gMember="$(groups ${1:-} 2>/dev/null)"
    [[ "${gMember[*]:2}" =~ ^(.* |)${dirVals[1]}( .*|)$ ]]                && return 0
  }
  [ "w" = "$(getfacl -pn "${2:-}" | grep user:${1:-}: | rev | cut -c2)" ] && return 0 || return 1
}