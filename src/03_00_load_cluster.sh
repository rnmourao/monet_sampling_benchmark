#!/bin/sh

# needs to be root to execute this script: sudo ./03_00_load_cluster.sh
# uses Docker version 17.03.1-ce, build c6d412e

./02_00_load.sh

# create workers
docker run -d -P --name monetdb-r-w1 --cpus="1" --memory="2g" monetdb/monetdb-r-docker
docker run -d -P --name monetdb-r-w2 --cpus="1" --memory="2g" monetdb/monetdb-r-docker

echo "done."
