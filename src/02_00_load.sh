#!/bin/sh

# needs to be root to execute this script: sudo ./02_00_load.sh
# uses Docker version 17.03.1-ce, build c6d412e

# change this path
# csvfile=/home/mourao/monet_sampling_benchmark/data
csvfile=/media/mourao/BACKUP/bolsa_familia/load

# removes old docker
echo "removing old docker..."
docker stop monetdb-r
id=$(docker ps -a | grep monetdb | cut -c-3)
docker rm $id

# gets monetdb-r docker from repository
echo "getting latest docker version from repository..."
docker pull monetdb/monetdb-r-docker

# executes docker and mounts csv file
echo "starting docker..."
docker run -d -P --name monetdb-r --cpus="1" --memory="2g" -v $csvfile:/tmp/data:ro  monetdb/monetdb-r-docker

# copies .monetdb into docker
echo "creating user and password file..."
echo "user=monetdb" > .monetdb
echo "password=monetdb" >> .monetdb
docker cp .monetdb monetdb-r:/root/.monetdb
rm .monetdb

# renames part file to load.csv
mv $csvfile/part*.csv $csvfile/load.csv

# copies load.sql into docker
echo "copying load.sql into docker..."
docker cp /home/mourao/monet_sampling_benchmark/src/02_01_load.sql monetdb-r:/tmp/02_01_load.sql

sleep 30

# executes load.sql
echo "executing ddl script..."
docker exec monetdb-r mclient -d db -i /tmp/02_01_load.sql

echo "done."
