#!/usr/bin/env bash

HOUSEKEEPING_FOLDER=$(dirname "${BASH_SOURCE[0]}")

status=0

cd $HOUSEKEEPING_FOLDER/..

for dir in services/*/; do
  dir=${dir%*/}
  service=${dir##*/}
  pushd $dir > /dev/null
  if [[ -e "bee" ]]; then
    ./bee prune_backups || status=$?
    echo -e "💠  Finished: ${service}\n"
  else
    echo -e "⛔  Unconfigured: ${service}\n"
  fi
  popd > /dev/null
done

exit $status
