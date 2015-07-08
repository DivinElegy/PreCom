#!/bin/bash
export DISPLAY=:0.0

tenfoot=false

while getopts "t" opt; do
  case $opt in
    t)
      tenfoot=true
      ;;
    \?)
      echo "Invalid option: -$OPTARG" >&2
      exit 1
      ;;
  esac
done


if [ $tenfoot = true ] ; then
    steam-debian -480p -tenfoot > /dev/null 2>&1
else
    steam-debian > /dev/null 2>&1
fi
