create_machineid() {
  # Create machine-id file
  if [ -x \$UUIDGEN ]; then
    \$UUIDGEN \$UUIDGEN_OPTS
  fi
}