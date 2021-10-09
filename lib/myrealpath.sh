myrealpath() {                  # real path of possible symlink
  [ -z "$@" ] && return 1
  command -v realpath >/dev/null && {
    realpath "$@"
  } || {
    [ -h "$@" ] && warning "Could not check for symbolic links. 
  Please install 'realpath' (package 'coreutils'),
  or provide real file path instead of symbolic link path.
  Possible symbolic link: $@"
    echo "$@"   ### FIXME: Maybe workaround with ls
    return 1
  }
}