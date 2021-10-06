getwslpath() {                  # get path to currently running WSL system

  # Fork from https://github.com/Microsoft/WSL/issues/2578#issuecomment-354010141
  
  local RUN_ID= BASE_PATH=
  
  RUN_ID="/tmp/$(makecookie)"

  # Mark our filesystem with a temporary file having an unique name.
  touch "${RUN_ID}"

  powershell.exe -Command '(Get-ChildItem HKCU:\Software\Microsoft\Windows\CurrentVersion\Lxss | ForEach-Object {Get-ItemProperty $_.PSPath}).BasePath.replace(":", "").replace("\", "/")' | while IFS= read -r BASEPATH; do
    # Remove trailing whitespaces.
    BASEPATH="${BASEPATH%"${BASEPATH##*[![:space:]]}"}"
    # Build the path on WSL.
    BASEPATH="/mnt/${BASEPATH,}/rootfs"

    # Current WSL instance doesn't have an access to its mount from within
    # itself despite all others are available. That's the hacky way we're
    # using to determine current instance.
    #
    # The second of part of the condition is a fallback for a case if our
    # trick will stop working. For that we've created a temporary file with
    # an unique name and now seeking it among all WLSs.
    if ! ls "${BASEPATH}" > /dev/null 2>&1 || [ -f "${BASEPATH}${RUN_ID}" ]; then
      echo "${BASEPATH}"
      # You can create and simultaneously run multiple WSL instances, comment
      # out the "break", run this script within each one and it'll return only
      # single value.
      break
    fi
  done
  rm "${RUN_ID}"
  return 0
}