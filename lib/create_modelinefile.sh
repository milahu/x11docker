create_modelinefile() {         # generate a set of smaller modelines for screen size $1 and store them in a cache file
  local Newmodelinefile Modeline Size X Y Xcount Ycount
  
  Size="${1:-}"
  X="$(echo "$Size" | cut -dx -f1)"
  Y="$(echo "$Size" | cut -dx -f2)"
  Newmodelinefile="$Modelinefilebasepath.$Size"
  
  [ -e "$Newmodelinefile" ] || {
    debugnote "$Xserver: Generating modelines for $Size"
    mkfile "$Newmodelinefile"
    for Ycount in 25 30 40 45 50 55 60 65 70 75 80 85 90 95 100; do
      for Xcount in 25 30 40 45 50 55 60 65 70 75 80 85 90 95 100; do
        Modeline="$(cvt "$(awk -v a="$X" -v b=$Xcount 'BEGIN {print (a * b / 100)}')" "$(awk -v a="$Y" -v b=$Ycount 'BEGIN {print (a * b / 100)}' )" | tail -n1)"
        Modeline="$(echo "$Modeline" | sed s/_60.00//g)"
        echo "$Modeline" >> "$Newmodelinefile"
      done
    done
  }
  
  echo "$Newmodelinefile"
}