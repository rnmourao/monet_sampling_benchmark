#!/bin/sh

csvfile=/media/mourao/BACKUP/bolsa_familia/load.csv

# gets monetdb-r docker from repository
docker pull monetdb/monetdb-r-docker

# executes docker and mounts csv file
docker run -d -P --name monetdb-r -v $csvfile:/tmp/load.csv:ro  monetdb/monetdb-r-docker

# copies load.sql into docker
docker cp /home/mourao/Documentos/bdm/monet_sampling_benchmark/src/load.sql monetdb-r:/tmp/load.sql

# executes load.sql
docker exec monetdb-r mclient -d db -i /tmp/load.sql
