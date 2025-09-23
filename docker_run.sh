#!/bin/bash

# docker system prune -a --volumes --force # Enable to delete volumes & clear up some storage space
# docker build -t mt4_setup:latest -f $1 .

if [[ "$1" == "Dockerfile-HKD" ]]; then
    echo -e "\n---++--- [ Building Image for HKD ] ---++---"
fi

if [[ "$1" == "Dockerfile-EH" ]]; then
    echo -e "\n---++--- [ Building Image for Eagle Hunter ] ---++---"
fi

if [[ "$1" == "Dockerfile-VP" ]]; then
    echo -e "\n---++--- [ Building Image for Vista Proxima ] ---++---"
fi

if [[ "$1" == "Dockerfile-AWS" ]]; then
    echo -e "\n---++--- [ Building Image for AWS Lambda Tech-Analysis ] ---++---"
fi

# not-recommended more resources
if [[ "$1" == "Dockerfile-VNC" ]]; then
    echo -e "\n---++--- [ Building Image w/ Built-in VNC ] ---++---"
fi

# docker container stop mt4 &> /dev/null
# docker container rm mt4 &> /dev/null
# docker-compose up -d # old version

# DOCKER_FILE=$1 docker compose --env-file .env up --build
DOCKER_FILE=$1 docker compose --env-file .env up -d

declare -a DEL_IMGS=(`docker image ls | grep '<none>' | awk '{print$3}'`)

echo -e "\nRemoving unused docker images..."

for i in ${DEL_IMGS}; do
    echo $i
    docker image rm $i
done 

echo -e '\n\nNOW ONLINE!! Go to site >> https://'
