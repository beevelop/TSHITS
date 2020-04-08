check_udp() {
  HOST=$1
  PORT=$2
  nc -uzv $HOST $PORT
  if [[ $? == 0 ]]; then
    echo "✅  [UDP-] ${HOST}:${PORT} is reachable"
    return 0
  else
    echo "📛  [UDP-] ${HOST}:${PORT} is not reachable"
    return 1
  fi
}

check_tcp() {
  HOST=$1
  PORT=$2
  nc -zv $HOST $PORT
  if [[ $? == 0 ]]; then
    echo "✅  [TCP-] ${HOST}:${PORT} is reachable"
    return 0
  else
    echo "📛  [TCP-] ${HOST}:${PORT} is not reachable"
    return 1
  fi
}

check_file() {
  FILE=$1
  if [[ -e $FILE ]]; then
    echo "✅  [FILE] ${FILE} does exist"
    return 0
  else
    echo "📛  [FILE] ${FILE} does not exist"
    return 1
  fi
}

check_traefik() {
  HOST=$1
  EXPECTED=$2
  REQ=`curl --header "Host: $HOST" -ksSI 127.0.0.1 | head -n1 | tr -d $'\r'` # \r is ^M and pollutes the string $
  if [[ "$REQ" == "$EXPECTED" ]]; then
    echo "✅  [TRFK] Got ${REQ} (${HOST})"
    return 0
  else
    echo "📛  [TRFK] Got ${REQ} (expected ${EXPECTED}) (${HOST})"
    return 1
  fi
}

check_curl() {
  URL=$1
  EXPECTED=$2

  REQ=`curl -m 3 -ksSI $1 | head -n1 | tr -d $'\r'` # \r is ^M and pollutes the string value
  if [[ "$REQ" == "$EXPECTED" ]]; then
    echo "✅  [CURL] Got ${REQ} (${URL})"
    return 0
  else
    echo "📛  [CURL] Got ${REQ} (expected ${EXPECTED}) (${URL})"
    return 1
  fi
}
