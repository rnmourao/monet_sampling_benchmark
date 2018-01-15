#!/bin/sh

# needs to be root to execute this script: sudo ./02_00_load.sh
# uses Docker version 17.03.1-ce, build c6d412e

# change this path
csvfile=/media/mourao/BACKUP/bolsa_familia/load

# remove old docker
echo "## REMOVING OLD DOCKERS ##"
docker rm -f $(docker ps -a | grep monetdb-r-docker | cut -c-3)

# get monetdb-r docker from repository
echo "## GETTING LATEST DOCKER VERSION FROM REPOSITORY ##"
docker pull monetdb/monetdb-r-docker

# execute docker and mounts csv file
echo "## STARTING DOCKER ##"
docker run -d -P --name monetdb-r --cpus="1" --memory="2g" -v $csvfile:/tmp/data:ro  monetdb/monetdb-r-docker

# copy .monetdb into docker
echo '## CREATING CREDENTIALS FILE ##'
echo "user=monetdb" > .monetdb
echo "password=monetdb" >> .monetdb
docker cp .monetdb monetdb-r:/root/.monetdb
rm .monetdb

# copy load.sql into docker
echo '## COPYING DDL SCRIPT INTO DOCKER ##'
docker cp /home/mourao/monet_sampling_benchmark/src/02_01_load.sql monetdb-r:/tmp/02_01_load.sql

sleep 30

# execute load.sql
echo '## EXECUTING DDL SCRIPT ##'
docker exec monetdb-r mclient -d db -i /tmp/02_01_load.sql

port=$(docker ps | grep monetdb-r | cut -d':' -f2 | cut -d'-' -f1)

echo '## DONE. MONETDB AVAILABLE ON LOCALHOST:' $port '##'
