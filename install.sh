#!/bin/bash

# Check if .env file exists
if [ -e .env ]; then
    source .env
else 
    echo "Please set up your .env file before starting your enviornment."
    exit 1
fi

mkdir -p data
docker-compose stop
docker container rm docker_openvpn_tap

# build, deploy and setup
docker build .
docker-compose up -d
docker-compose run --rm docker_openvpn_tap ovpn_genconfig -u udp://$HOSTNAME
docker-compose run --rm docker_openvpn_tap ovpn_initpki

# stop and copy the real configuration
docker-compose stop
cp data/openvpn.conf data/openvpn.bak
cp actual_openvpn.conf data/openvpn.conf

# start once again
docker-compose up -d

echo "Done setting up."