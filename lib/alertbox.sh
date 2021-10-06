alertbox() {                    # X alert box with title $1 and message $2
  local Title Message
  Title="${1:-}"
  Message="${2:-}"

  Message="$(echo "$Message" | LANG=C sed "s/[\x80-\xFF]//g" | fold -w120 )" # remove UTF-8 special chars; line folding at 120 chars

  # try some tools to show alert message. If all tools fail, return 1
  command -v   xmessage     >/dev/null && [ -n "${DISPLAY:-}" ] && {
    echo "$Title

$Message" | xmessage  -file - -default okay ||:
  } || {
    command -v gxmessage    >/dev/null && [ -n "${DISPLAY:-}" ] && {
      echo "$Title

$Message" | gxmessage -file - -default okay ||:
    }
  } || {
    command -v zenity       >/dev/null && [ -n "${DISPLAY:-}" ] && {
      zenity --error --no-markup --ellipsize --title="$Title" --text="$Message" 2>/dev/null ||:
    }
  } || {
    command -v yad          >/dev/null && [ -n "${DISPLAY:-}" ] && {
      yad  --image "dialog-error" --title "$Title" --button=gtk-ok:0 --text "$(echo "$Message" | sed 's/\\/\\\\/g')" --fixed 2>/dev/null ||:
    }
  } || {
    command -v kaptain      >/dev/null && [ -n "${DISPLAY:-}" ] && {
      echo 'start "'$Title'" -> message @close=" cancel" ;
            message "'$(echo "$Message" | sed 's/\\/\\\\\\/g' | sed 's/"/\\"/g' | sed -E ':a;N;$!ba;s/\r{0,1}\n/\\n/g' )'" -> @fill ;'  | kaptain ||:
    }
  } || {
    command -v kdialog      >/dev/null && [ -n "${DISPLAY:-}" ] && {
      kdialog --title "$Title" --error "$(echo "$Message" | sed 's/\\/\\\\/g' )" 2>/dev/null ||:
    }
  } || {
    command -v xterm        >/dev/null && [ -n "${DISPLAY:-}" ] && {
      xterm -title "$Title" -e "echo '$(echo "$Message" | sed "s/'/\"/g")' ; read -n1" ||:
    }
  } || {
    [ -n "$Passwordterminal" ] && [ "$Passwordterminal" != "eval" ] && [ -e "$Cachefolder" ] && {
      mkfile $Cachefolder/message
      echo "#! /usr/bin/env bash
echo '$Title

$Message
(Press any key to close window)'
read -n1
:
" >> $Cachefolder/message
      $Passwordterminal /usr/bin/env bash $Cachefolder/message
    }
  } || {
    notify-send "$Title:

$Message" 2>/dev/null
  } || {
    warning "Could not display message on X:
$Message"
    return 1
  }
  return 0
}