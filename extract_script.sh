#. create_dockerrc.sh

#set -o xtrace # noisy debug

infile=lib/create_dockerrc.sh

infilebase=${infile%.*}

vars="$(grep -o -E '\$[a-zA-Z][a-zA-Z0-9]*' $infile | sort --uniq | grep -v '^\$PATH$')"

# set vars
# varname='$varname'
varsEval="$(echo "$vars" | sed -E "s/^\\\$(.+)\$/\1='\\\$TPLCONST__\1__TPLCONST'/")"
echo $'eval vars:\n'"$varsEval"$':eval vars'
eval "$varsEval"

# source infile
#eval ". $infile"

# we must source all libs
. x11docker

# TODO manually set "switch vars"
# -> manually move all switching code to the template file
Winsubsystem=""
# FIXME replace yes/no with true/false and use: if $Debugmode; then ....; fi
Debugmode="yes"
Containersetup="yes"
Containerenvironmentcount=1 # lib/store_runoption.sh
Sharevolumescount=1
Containerenvironment=("TODO__Containerenvironment_idx_0__TODO")
Sharevolumes=("TODO__Sharevolumes_idx_0__TODO")

# call function
fname=$(basename "$infile" .sh)
echo "call fn $fname"
callEval="$fname '\$fnarg1' '\$fnarg2' '\$fnarg3' '\$fnarg4' '\$fnarg5' '\$fnarg6' '\$fnarg7' '\$fnarg8' '\$fnarg9' '\$fnarg10'"
#echo $'eval call:\n'"$callEval"$':eval call'
eval "$callEval" > "$infilebase.tpl.sh"

# manually replace $PATH
# TODO maybe escape $PATH for regex
sed -i "s|$PATH|\$TPLCONST__PATH__TPLCONST|g" "$infilebase.tpl.sh"

# fix single quotes to double quotes

echo "$vars"$'\n''$PATH' | sed -E "s/^\\\$(.+)\$/\1/" | while read varName
do
  sed -i -E "s|'"'(\$TPLCONST__'"${varName}__TPLCONST)'|\"\\1\"|" "$infilebase.tpl.sh"
done

# insert magic comment: #%DEFINE_ALL_TPLCONST
sed -i -E 's|(#! /usr/bin/env bash)|\1\n\n#%DEFINE__ALL__TPLCONST\n|' "$infilebase.tpl.sh"

# generate the "call template" code

{
  echo "$fname() {"
  echo "# put all vars in one line, to keep line numbers between template and result file"
  echo "s=\"\""
  echo "$vars"$'\n''$PATH' | sed -E "s/^\\\$(.+)\$/\1/" | while read varName
  do
    echo "s+=\"TPLCONST__${varName}__TPLCONST=\\\"\$${varName}\\\"; \""
    sed -i -E "s|'"'(\$TPLCONST__'"${varName}__TPLCONST)'|\"\\1\"|" "$infilebase.tpl.sh"
  done
  echo "fsed1file \"$infilebase.tpl.sh\" '^#%DEFINE__ALL__TPLCONST$' \"\$s\""
  echo "}"
} > "$infilebase.call-tpl.sh"


echo "done $infilebase.tpl.sh"
echo "done $infilebase.call-tpl.sh"

