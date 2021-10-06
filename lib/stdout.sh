stdout() {
  echo \"\$*:STDOUT\"    | sed \"s/\\\$/ /\" >>\$Messagefile
}