finish_sigint() {               # trap SIGINT to activate debug mode on finish()
  local Pid1pid
  Debugmode="yes"
  debugnote "Received SIGINT"
  storeinfo error=130
  finish
}