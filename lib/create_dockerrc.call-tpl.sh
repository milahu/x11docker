create_dockerrc() {
# put all vars in one line, to keep line numbers between template and result file
s=""
s+="TPLCONST__BASH__TPLCONST=\"$BASH\"; "
s+="TPLCONST__Cachefolder__TPLCONST=\"$Cachefolder\"; "
s+="TPLCONST__Cmdrc__TPLCONST=\"$Cmdrc\"; "
s+="TPLCONST__Cmdstderrlogfile__TPLCONST=\"$Cmdstderrlogfile\"; "
s+="TPLCONST__Cmdstdinfifo__TPLCONST=\"$Cmdstdinfifo\"; "
s+="TPLCONST__Cmdstdoutlogfile__TPLCONST=\"$Cmdstdoutlogfile\"; "
s+="TPLCONST__Containerarchitecture__TPLCONST=\"$Containerarchitecture\"; "
s+="TPLCONST__Containerbackend__TPLCONST=\"$Containerbackend\"; "
s+="TPLCONST__Containerbackendbin__TPLCONST=\"$Containerbackendbin\"; "
s+="TPLCONST__Containercommand__TPLCONST=\"$Containercommand\"; "
s+="TPLCONST__Containerenvironmentfile__TPLCONST=\"$Containerenvironmentfile\"; "
s+="TPLCONST__Containerid__TPLCONST=\"$Containerid\"; "
s+="TPLCONST__Containerip__TPLCONST=\"$Containerip\"; "
s+="TPLCONST__Containerlogfile__TPLCONST=\"$Containerlogfile\"; "
s+="TPLCONST__Containername__TPLCONST=\"$Containername\"; "
s+="TPLCONST__Containerrc__TPLCONST=\"$Containerrc\"; "
s+="TPLCONST__Containerrootrc__TPLCONST=\"$Containerrootrc\"; "
s+="TPLCONST__Containersetup__TPLCONST=\"$Containersetup\"; "
s+="TPLCONST__Containeruser__TPLCONST=\"$Containeruser\"; "
s+="TPLCONST__Containeruserhome__TPLCONST=\"$Containeruserhome\"; "
s+="TPLCONST__Containeruserhosthome__TPLCONST=\"$Containeruserhosthome\"; "
s+="TPLCONST__Containeruseruid__TPLCONST=\"$Containeruseruid\"; "
s+="TPLCONST__Count__TPLCONST=\"$Count\"; "
s+="TPLCONST__Createcontaineruser__TPLCONST=\"$Createcontaineruser\"; "
s+="TPLCONST__DEBIAN__TPLCONST=\"$DEBIAN\"; "
s+="TPLCONST__Dbus__TPLCONST=\"$Dbus\"; "
s+="TPLCONST__Dbusrunsession__TPLCONST=\"$Dbusrunsession\"; "
s+="TPLCONST__Dbussystem__TPLCONST=\"$Dbussystem\"; "
s+="TPLCONST__Debugmode__TPLCONST=\"$Debugmode\"; "
s+="TPLCONST__Dockercommand__TPLCONST=\"$Dockercommand\"; "
s+="TPLCONST__Dockercommandfile__TPLCONST=\"$Dockercommandfile\"; "
s+="TPLCONST__Dockerimagelistfile__TPLCONST=\"$Dockerimagelistfile\"; "
s+="TPLCONST__Dockerinfofile__TPLCONST=\"$Dockerinfofile\"; "
s+="TPLCONST__Dockerlogspid__TPLCONST=\"$Dockerlogspid\"; "
s+="TPLCONST__Dockerstopsignalfifo__TPLCONST=\"$Dockerstopsignalfifo\"; "
s+="TPLCONST__Entrypoint__TPLCONST=\"$Entrypoint\"; "
s+="TPLCONST__Exec__TPLCONST=\"$Exec\"; "
s+="TPLCONST__Failure__TPLCONST=\"$Failure\"; "
s+="TPLCONST__Forwardstdin__TPLCONST=\"$Forwardstdin\"; "
s+="TPLCONST__HOME__TPLCONST=\"$HOME\"; "
s+="TPLCONST__Homesoftlink__TPLCONST=\"$Homesoftlink\"; "
s+="TPLCONST__Hostarchitecture__TPLCONST=\"$Hostarchitecture\"; "
s+="TPLCONST__Hostdisplay__TPLCONST=\"$Hostdisplay\"; "
s+="TPLCONST__Hostlocaltimefile__TPLCONST=\"$Hostlocaltimefile\"; "
s+="TPLCONST__Hostuser__TPLCONST=\"$Hostuser\"; "
s+="TPLCONST__Hostutctime__TPLCONST=\"$Hostutctime\"; "
s+="TPLCONST__Imagename__TPLCONST=\"$Imagename\"; "
s+="TPLCONST__Imagepull__TPLCONST=\"$Imagepull\"; "
s+="TPLCONST__Imageuser__TPLCONST=\"$Imageuser\"; "
s+="TPLCONST__Initsystem__TPLCONST=\"$Initsystem\"; "
s+="TPLCONST__Inspect__TPLCONST=\"$Inspect\"; "
s+="TPLCONST__Interactive__TPLCONST=\"$Interactive\"; "
s+="TPLCONST__LINENO__TPLCONST=\"$LINENO\"; "
s+="TPLCONST__Line__TPLCONST=\"$Line\"; "
s+="TPLCONST__Logfile__TPLCONST=\"$Logfile\"; "
s+="TPLCONST__Messagefifo__TPLCONST=\"$Messagefifo\"; "
s+="TPLCONST__Messagefifofuncs__TPLCONST=\"$Messagefifofuncs\"; "
s+="TPLCONST__Mobyvm__TPLCONST=\"$Mobyvm\"; "
s+="TPLCONST__Newdisplay__TPLCONST=\"$Newdisplay\"; "
s+="TPLCONST__Newdisplaynumber__TPLCONST=\"$Newdisplaynumber\"; "
s+="TPLCONST__Newwaylandsocket__TPLCONST=\"$Newwaylandsocket\"; "
s+="TPLCONST__Newxenv__TPLCONST=\"$Newxenv\"; "
s+="TPLCONST__Noentrypoint__TPLCONST=\"$Noentrypoint\"; "
s+="TPLCONST__Passwordneeded__TPLCONST=\"$Passwordneeded\"; "
s+="TPLCONST__Path__TPLCONST=\"$Path\"; "
s+="TPLCONST__Persistanthomevolume__TPLCONST=\"$Persistanthomevolume\"; "
s+="TPLCONST__Pid1pid__TPLCONST=\"$Pid1pid\"; "
s+="TPLCONST__Pullimage__TPLCONST=\"$Pullimage\"; "
s+="TPLCONST__Pythonbin__TPLCONST=\"$Pythonbin\"; "
s+="TPLCONST__Runasuser__TPLCONST=\"$Runasuser\"; "
s+="TPLCONST__Runsinterminal__TPLCONST=\"$Runsinterminal\"; "
s+="TPLCONST__Runtime__TPLCONST=\"$Runtime\"; "
s+="TPLCONST__Setupwayland__TPLCONST=\"$Setupwayland\"; "
s+="TPLCONST__Sharecgroup__TPLCONST=\"$Sharecgroup\"; "
s+="TPLCONST__Sharegpu__TPLCONST=\"$Sharegpu\"; "
s+="TPLCONST__Sharehome__TPLCONST=\"$Sharehome\"; "
s+="TPLCONST__Signal__TPLCONST=\"$Signal\"; "
s+="TPLCONST__Storeinfofile__TPLCONST=\"$Storeinfofile\"; "
s+="TPLCONST__Storepidfile__TPLCONST=\"$Storepidfile\"; "
s+="TPLCONST__Sudo__TPLCONST=\"$Sudo\"; "
s+="TPLCONST__Switchcontaineruser__TPLCONST=\"$Switchcontaineruser\"; "
s+="TPLCONST__Timetosaygoodbyefifo__TPLCONST=\"$Timetosaygoodbyefifo\"; "
s+="TPLCONST__Timetosaygoodbyefile__TPLCONST=\"$Timetosaygoodbyefile\"; "
s+="TPLCONST__Ungrep__TPLCONST=\"$Ungrep\"; "
s+="TPLCONST__Wantcgroup__TPLCONST=\"$Wantcgroup\"; "
s+="TPLCONST__Winpty__TPLCONST=\"$Winpty\"; "
s+="TPLCONST__Winsubsystem__TPLCONST=\"$Winsubsystem\"; "
s+="TPLCONST__Workdir__TPLCONST=\"$Workdir\"; "
s+="TPLCONST__XDG__TPLCONST=\"$XDG\"; "
s+="TPLCONST__Xauthentication__TPLCONST=\"$Xauthentication\"; "
s+="TPLCONST__Xiniterrorcodes__TPLCONST=\"$Xiniterrorcodes\"; "
s+="TPLCONST__Xinitlogfile__TPLCONST=\"$Xinitlogfile\"; "
s+="TPLCONST__Xserver__TPLCONST=\"$Xserver\"; "
s+="TPLCONST__PATH__TPLCONST=\"$PATH\"; "
fsed1file "lib/create_dockerrc.tpl.sh" '^#%DEFINE__ALL__TPLCONST$' "$s"
}