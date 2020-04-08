echo "Do not run this script (just example bash here)"
exit 0
export CLIENTNAME="your_client_name"
docker-compose run --rm openvpn easyrsa build-client-full $CLIENTNAME
docker-compose run --rm openvpn ovpn_getclient $CLIENTNAME > $CLIENTNAME.ovpn
