mysleep() {                     # catch cases where sleep only supports integer
  sleep "${1:-1}" 2>/dev/null || sleep 1
}