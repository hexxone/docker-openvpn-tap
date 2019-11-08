#!/bin/bash

docker-compose run --rm docker_openvpn_tap ovpn_revokeclient $1 remove

rm -f clients/$1.ovpn