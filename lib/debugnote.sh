debugnote() {
  echo \"\$*:DEBUGNOTE\" | sed \"s/\\\$/ /\" >>\$Messagefile
}