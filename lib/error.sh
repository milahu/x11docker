error() {
  echo \"\$*:ERROR\"     | sed \"s/\\\$/ /\" >>\$Messagefile
  exit 64
}