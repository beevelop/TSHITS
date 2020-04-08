#!/usr/bin/env bash

META_FOLDER=$(dirname "${BASH_SOURCE[0]}")
. $META_FOLDER/checks.sh

BEEPASS=${BEEPASS:-`cat $META_FOLDER/../.bee.pass`}
ENVIRON=${ENVIRON:-`cat $META_FOLDER/../.bee.environ`}

slug=${SERVICE,,}

ENC_PREFIX=".enc"

sub_health() {
  echo "❤️  Healthchecking ${SERVICE}"
  if [[ -n "$1" ]]; then
    loadenv $1
  fi

  do_health
}

sub_hide_secrets() {
  echo "👻  Hiding all secrets for ${SERVICE} (files starting with ${ENC_PREFIX})"
  # rm .enc.*
  # should rm .env.*
  # maybe encrypt first?
}

# Checks if all prerequisits for encrypting / decrypting are met
check_enc_dec_reqs() {
  if [[ -z "$BEEPASS" ]]; then
    echo "Please provide the BEEPASS env to enable encryption / decryption"
    exit 1
  fi
}

sub_decrypt() {
  check_enc_dec_reqs
  environ=${1:-"$ENVIRON"}
  CONF_DEC=".env.${environ}"
  CONF_ENC="${ENC_PREFIX}${CONF_DEC}"
  echo "🔓  Decrypting ${CONF} for ${SERVICE}"
  openssl aes-256-cbc -d -in "$CONF_ENC" -out "$CONF_DEC" -k "${BEEPASS}"
}

sub_encrypt() {
  check_enc_dec_reqs
  environ=${1:-"$ENVIRON"}
  CONF_DEC=".env.${environ}"
  CONF_ENC="${ENC_PREFIX}${CONF_DEC}"
  echo "🔒  Encrypting ${CONF} for ${SERVICE}"
  openssl aes-256-cbc -salt -in "$CONF_DEC" -out "$CONF_ENC" -k "${BEEPASS}"
}

sub_backup() {
  if [[ ! -e "backups/" ]]; then
    sudo restic init --password-file ../../restic.pass --repo ./backups
  fi

  sudo restic -r ./backups --password-file ../../restic.pass backup ./data
}

sub_prune_backups() {
  if [[ ! -e "backups/" ]]; then
    echo "Backups folder does not exist for this service. Exiting gracefully."
    exit 0
  fi

  sudo restic -r ./backups --password-file ../../restic.pass forget --keep-last 1 --prune
}

sub_restic() {
  echo "export RESTIC_PASSWORD=`cat ../../restic.pass`"
  echo "export RESTIC_REPOSITORY=`pwd`/backups"
  echo "# Run this command to configure your shell:"
  echo '# eval "$(./bee restic)"'
}

sub_launch() {
  echo "🚀  Launching ${SERVICE}"
  function_exists do_launch && do_launch || (docker-compose pull && docker-compose up -d)
}

sub_pull() {
  echo "💾  Pulling ${SERVICE}"
  function_exists do_pull && do_pull || docker-compose pull
}

sub_prepare() {
  echo "☕️  Preparing ${SERVICE}"
  function_exists do_prepare && do_prepare
}

sub_nuke() {
  echo "💣  Nuking ${SERVICE}"
  docker-compose down --remove-orphans --rmi all
  function_exists do_nuke && do_nuke
}

sub_down() {
  echo "💀  Stopping ${SERVICE}"
  docker-compose down --remove-orphans
}

sub_logs() {
  loadenv $1
  docker-compose logs -f
}

sub_up() {
  loadenv $1
  sub_prepare
  sub_launch
  wait ${WAIT_TIME:-7}
  sub_health
  return $?
}

sub_upgrade() {
  sub_backup
  function_exists do_upgrade && do_upgrade
  sub_up
}

wait() {
  SECONDS=$1
  echo "⏳  Waiting ${SECONDS} seconds for the service to start..."
  sleep $SECONDS
}

sub_test() {
  echo "🔮  Testing ${SERVICE}"
  sub_up "test"
  HEALTH=$?
  if [[ $HEALTH -ne 0 ]]; then
    echo "⚠️  Tests unsuccessful: At least one test failed"
    docker-compose logs
  fi

  if [[ -z "$SKIP_NUKE" ]]; then
    sub_nuke
  fi

  echo "🍻  Finished testing routine"
  exit $HEALTH
}

loadenv() {
  CONF=".env"
  environ=${1:-"${ENVIRON}"}
  if [[ -n "$environ" ]]; then
    CONF="${CONF}.${environ}"
  fi

  if [[ -e $CONF ]]; then
    echo "#🎛  Loading configuration file (${CONF})"
    export $(egrep -v '^#' $CONF | xargs)
  else
    echo "💩  ${CONF} does not exist! Checking for encrypted version."
    if [[ -e "${ENC_PREFIX}${CONF}" ]]; then
      sub_decrypt "$1"
      echo "#🎛  Loading configuration file (${CONF})"
      export $(egrep -v '^#' $CONF | xargs)
    else
      exit 1
    fi
  fi
}

sub_help() {
    echo "Usage: ./bee COMMAND [options]"
    echo ""
    echo "Commands:"
    echo "    prepare   Prepares the service for launch (e.g. folders, files, configs,...)"
    echo "    launch    Launches the service (overwrite with do_launch)"
    echo "    health    Checks if the service is running properly"
    echo "    backup    Make a local backup to the ./backup folder using restic"
    echo "    up [ENV]  Prepares, launches and checks the service for the provided ENV"
    echo ""
    echo "Helpers:"
    echo "    encrypt [ENV]  Encrypts the .env file for the provided ENV"
    echo "    decrypt [ENV]  Decrypts the .env file for the provided ENV"
    echo "    upgrade   Upgrade a service (combines backup and up)"
    echo ""
    echo "DANGERZONE (don't mess with this shit... seriously):"
    echo "    nuke      Kills the service and removes all traces (image, files, configs,...)"
}

function_exists() {
  declare -f -F $1 > /dev/null
  return $?
}

sub=$1
loadenv
case $sub in
    "" | "-h" | "--help")
        sub_help
        ;;
    *)
        shift
        sub_${sub} $@
        if [ $? = 127 ]; then
            echo "Error: '$sub' is not a known subcommand." >&2
            echo "       Run './bee --help' for a list of known subcommands." >&2
            exit 1
        fi
        ;;
esac
