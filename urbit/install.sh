#!/bin/bash
set -e

usage() {
  printf "Usage: %s [-hwxv] URBIT_DESK_DIRECTORY
(-h: show this help)
(-w: flag to watch and live copy code)
(-x: set excludes file, default=ignore_files.txt)
(-v: verbose)
" "${0}" 1>&2;
  exit 1;
}

if [ $# -eq 0 ]; then
  usage
  exit 2
fi

desk='/home/armitage/urbit/syx/volt'
verbose=false
watch=false
excludes=ignore_files.txt

while getopts 'wxv:?h' opt;
do
  case "${opt}" in
    w) watch=true ;;
    x) excludes="${OPTARG}" ;;
    v) verbose=true ;;
    h|?) usage ;;
  esac
done

shift $((OPTIND-1))

if $verbose ; then
  set -x
fi

desk="$1"

sync_files () {
  rsync -r --exclude-from="${excludes}" ./* "${desk}"/
}

if $watch ; then
  echo "Watching for changes to copy to ${desk}..."
  while true
  do
    sleep 0.8
    sync_files
  done
else
  sync_files
  echo "Installed."
fi
