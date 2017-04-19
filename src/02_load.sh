#!/bin/sh

# need to be root to execute this script: sudo ./02_load.sh

# change this path
# csvfile=/home/mourao/Documentos/bdm/monet_sampling_benchmark/data
csvfile=/media/mourao/BACKUP1/bolsa_familia

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
docker run -d -P --name monetdb-r -v $csvfile:/tmp/data:ro  monetdb/monetdb-r-docker

# copies .monetdb into docker
echo "creating user and password file..."
echo "user=monetdb\npassword=monetdb" > .monetdb
docker cp .monetdb monetdb-r:/root/.monetdb
rm .monetdb

# creates farm
# echo "creating dbfarm..."
# docker exec monetdb-r monetdbd create /tmp/bdm
# monetdbd set port=50001 /tmp/bdm
# docker exec monetdb-r monetdbd start /tmp/bdm

# creates database
# echo "creating database..."
# docker exec monetdb-r monetdb create bdm
# docker exec monetdb-r monetdb release bdm

# copies load.sql into docker
echo "copying load.sql into docker..."
docker cp /home/mourao/Documentos/bdm/monet_sampling_benchmark/src/load.sql monetdb-r:/tmp/load.sql

sleep 5

# executes load.sql
echo "executing ddl script..."
docker exec monetdb-r mclient -d db -i /tmp/load.sql

echo "done."
