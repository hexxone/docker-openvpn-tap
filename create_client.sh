#!/bin/bash

mkdir -p clients

docker-compose run --rm docker_openvpn_tap easyrsa build-client-full $1 nopass

docker-compose run --rm docker_openvpn_tap ovpn_getclient $1 > clients/$1.ovpn
