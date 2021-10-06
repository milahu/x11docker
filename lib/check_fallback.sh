check_fallback() {
  # Option --fallback
  case $Fallback in
    no) error "Option --fallback=no: Fallbacks are disabled. 
    x11docker cannot fulfill an option you have chosen, see message above." ;;
  esac
}