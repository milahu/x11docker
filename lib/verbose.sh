verbose() {
  echo \"\$*:VERBOSE\"   | sed \"s/\\\$/ /\" >>\$Messagefile
}