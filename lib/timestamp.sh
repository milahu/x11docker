timestamp() {                   # print HH:MM:SS,NNN
  date +%T,%N | cut -c1-12
}