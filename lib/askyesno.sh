askyesno() {                    # ask Yes/no question. Default 'yes' for ENTER, timeout with 'no' after 60s
  local Choice
  read -t60 -n1 -p "(timeout after 60s assuming no) [Y|n]" Choice
  [ "$?" = '0' ] && {
    [[ "$Choice" == [YyJj]* ]] || [ -z "$Choice" ] && return 0
  }
  return 1
}