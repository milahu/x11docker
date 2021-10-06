note() {
  echo \"\$*:NOTE\"      | sed \"s/\\\$/ /\" >>\$Messagefile
}