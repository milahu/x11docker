warning() {
  echo \"\$*:WARNING\"   | sed \"s/\\\$/ /\"  >>\$Messagefile
}