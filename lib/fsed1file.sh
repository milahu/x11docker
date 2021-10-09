#!/usr/bin/env bash

# template processor

# https://stackoverflow.com/a/69479243/10440128
# fixed string editor. replace first match in file
fsed1file() {
  tplFile="$1"
  pattern="$2"
  replace="$3"
  match="$(grep -b -m 1 -o -E "$pattern" "$tplFile")"
  offset1=$(echo "$match" | cut -d: -f1)
  match="$(echo "$match" | cut -d: -f2-)"
  matchLength=${#match}
  offset2=$(expr $offset1 + $matchLength)
  dd bs=1 if="$tplFile" count=$offset1 status=none
  echo -n "$replace"
  dd bs=1 if="$tplFile" skip=$offset2 status=none
}

# sample: fsed1file "sample.tpl.sh" "^#%TEMPLATE_CONSTANTS$" "a=1; b=2"
