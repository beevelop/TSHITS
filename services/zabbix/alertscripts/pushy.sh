#!/bin/bash
set -e

# Replace this token before using! 
TOKEN="3Z8d6D4nyZ5PaGgFsiM4Gdus2gSeBdKBnBRCQA7A"

errorTitle="Error: No title set"
errorBody="Error: No body set"
defaultTo="3Z8d6D4nyZ5PaGgFsiM4Gdus2gSeBdKBnBRCQA7A" # and this one too
to=${1:-$defaultTo}
subject=${2:-$errorTitle}
body=${3:-$errorBody}

curl -s \
  -F "token=$TOKEN" \
  -F "user=$to" \
  -F "title=$subject" \
  -F "message=$body" \
  -F "priority=1" \
  https://api.pushover.net/1/messages.json

