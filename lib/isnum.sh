isnum() {                       # check if $1 is a number
  [ "1" = "$(awk -v a="${1:-}" 'BEGIN {print (a == a + 0)}')" ]
}