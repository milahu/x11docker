buildimage() {                  # --build: build image from x11docker repository Dockerfile
  # Build image $1 from x11docker repository
  
  local Wwwpath Buildpath Imagename
  
  # check image name, should have leading 'x11docker/'
  Imagename="${1:-}"
  grep -q "x11docker" <<< "$Imagename" || Imagename="x11docker/$Imagename"
  
  # remote and local pathes
  Wwwpath="https://raw.githubusercontent.com/mviereck/dockerfile-$(tr / - <<< "$Imagename")/master/Dockerfile"
  Buildpath="${TMPDIR:-/tmp}/x11docker-build-$(unspecialstring "$Imagename")"
  
  grep -q "dockerfile-x11docker-" <<< "$Wwwpath" || error "Option --build: x11docker only supports building of
  images provided at x11docker repository https://github.com/mviereck"
  
  mkdir -p "$Buildpath"
  cd $Buildpath
  download || error "Option --build: Please install 'curl' or 'wget' to allow a download"
  
  note "Download of $Wwwpath"
  download "$Wwwpath" "$Buildpath/Dockerfile" || error "Option --build: Did not find a Dockerfile for $Imagename
  at $Wwwpath"
  
  note "Building $Imagename"
  $Containerbackendbin build -t "$Imagename" "$Buildpath" || error "Option --build: Building image '$Imagename' failed."
  
  rm -rf "$Buildpath"
  return 0
}