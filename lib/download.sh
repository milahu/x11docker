download() {                    # download file at URL $1 and store it in file $2
  # Uses wget or curl. If both are missing, returns 1. 
  # With no arguments it checks for curl/wget without downloading.
  # Download follows redirects. 
  local Downloader=
  command -v wget >/dev/null && Downloader="wget"
  command -v curl >/dev/null && Downloader="curl"
  [ "$Downloader" ] || return 1
  [ "${1:-}" ]      || return 0
  case $Downloader in
    wget) wget    "${1:-}" -O       "${2:-}" ;;
    curl) curl -L "${1:-}" --output "${2:-}" ;;
  esac
}