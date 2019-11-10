#!/bin/bash

# Check if .env file exists
if [ -e .env ]; then
    source .env
else 
    echo "Please set up your .env file before starting your enviornment."
    exit 1
fi

# shutdown & remove container
docker-compose down

# copy client config dir profiles
mkdir -p data
#cp -r ccd/ data/ccd/

# build, deploy and setup keys
docker-compose up -d --build --force-recreate
docker-compose run --rm docker_openvpn_tap ovpn_initpki

# restart to avoid OpenVpn accidentally blocking the interface.
# also required to load the freshly generated keys
docker-compose restart

echo "Done setting up."