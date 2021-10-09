verbose() {                     # show verbose messages
  # only logfile notes here, terminal output is done with tail in setup_verbosity()
  logentry "x11docker[$(timestamp)]: $*
"
}