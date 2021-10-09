rmcr() {                        # remove carriage return to translate DOS/Windows newlines into UNIX newlines
  # convert stdin if $1 is empty. Otherwise convert file $1.
  case "${1:-}" in
    "") sed    "s/$(printf "\r")//g" ;;
    *)  sed -i "s/$(printf "\r")//g"  "${1:-}" ;;
  esac
}