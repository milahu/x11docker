unspecialstring() {             # replace special chars of $1 with -
  # Replace all characters except those described in "a-zA-Z0-9_" with a '-'. 
  # Replace newlines, too.
  # Remove leading and trailing '-'
  # Avoid double '--'
  # Return empty string if only special chars are given.
  printf %s "${1:-}" | LC_ALL=C tr -cs "a-zA-Z0-9_" "-" | sed -e 's/^-// ; s/-$//'
}