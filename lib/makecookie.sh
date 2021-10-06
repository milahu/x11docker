makecookie() {                  # bake a cookie
  mcookie 2>/dev/null || echo $RANDOM$RANDOM$RANDOM$RANDOM$RANDOM$RANDOM | cut -b1-32
}