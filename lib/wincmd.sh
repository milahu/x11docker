wincmd() {                      # execute a command on MS Windows with cmd.exe
  MSYS2_ARG_CONV_EXCL='*' cmd.exe /C "${@//&/^&}" | rmcr
}