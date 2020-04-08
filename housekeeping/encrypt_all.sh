#!/usr/bin/env bash

set -e

HOUSEKEEPING_FOLDER=$(dirname "${BASH_SOURCE[0]}")

INSTANCE="${1}"

if [[ -z "$INSTANCE" ]]; then
  echo "Please provide the INSTANCE name as the first argument: e.g."
  echo "./encrypt_all foobar"
  exit 1
fi

status=0

cd $HOUSEKEEPING_FOLDER/..

for dir in services/*/; do
  dir=${dir%*/}
  service=${dir##*/}
  pushd $dir > /dev/null
  if [[ -e "bee" ]]; then
    ./bee encrypt "${INSTANCE}" || status=$?
    echo -e "💠  Finished: ${service}\n"
  else
    echo -e "⛔  Unconfigured: ${service}\n"
  fi
  popd > /dev/null
done

exit $status
