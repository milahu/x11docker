escapestring() {                # escape special chars of $1
  # escape all characters except those described in [^a-zA-Z0-9,._+@=:/-]
  echo "${1:-}" | LC_ALL=C sed -e 's/[^a-zA-Z0-9,._+@=:/-]/\\&/g; '
}