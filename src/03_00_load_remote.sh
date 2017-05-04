#!/bin/sh

# needs to be root to execute this script: sudo ./03_00_load_remote.sh
# uses Docker version 17.03.1-ce, build c6d412e

# change this path
# csvfile=/home/mourao/monet_sampling_benchmark/data
csvfile=/media/mourao/BACKUP/bolsa_familia/load

# remove old docker
echo '## REMOVING OLD DOCKERS ##'
docker rm -f $(docker ps -a | grep monetdb-r-docker | cut -c-3)

# get monetdb-r docker from repository
echo '## GETTING LATEST DOCKER VERSION FROM REPOSITORY ##'
docker pull monetdb/monetdb-r-docker

# create .monetdb file
echo '## CREATING CREDENTIALS FILE ##'
echo 'user=monetdb' > .monetdb
echo 'password=monetdb' >> .monetdb

# rename part file to load.csv
echo '## CHANGING NAME OF OLD LOAD FILE ##'
mv $csvfile/part*.csv $csvfile/load.csv

# split load.csv into 7 files, one for each year.
echo '## SPLITTING LOAD FILE INTO SEVERAL FILES, ONE FOR EACH YEAR ##'
## awk -F, '{print > "'$csvfile'/"substr($2,1,4)".csv"}' $csvfile/load.csv

# create workers
echo '## CREATING WORKERS ##'
for i in $( ls -1 $csvfile/20*.csv | grep -o '.\{8\}$' | cut -d. -f1 ); do
  name=MONETDB-$i

  # executes docker and mounts csv file
  echo '## STARTING WORKER '$name' ##'
  docker run -d -P --name $name --cpus='1' --memory='2g' -v $csvfile:/tmp/data:ro  monetdb/monetdb-r-docker

  echo '## WAITING ##'
  sleep 30

  # copy .monetdb into docker
  echo '## COPYING CREDENTIALS FILE ##'
  docker cp .monetdb $name:/root/.monetdb

  # copies load.sql into docker
  echo '## COPYING DDL SCRIPT INTO WORKER ##'
  docker cp /home/mourao/monet_sampling_benchmark/src/03_01_load.sql $name:/tmp/03_01_load.sql

  # change the filename within the load.sql file
  echo '## ADAPTING DDL SCRIPT TO WORKER ##'
  docker exec $name sed -i 's/@YEAR@/'$i'/g' /tmp/03_01_load.sql

  # executes load.sql
  echo '## EXECUTING DDL SCRIPT ##'
  docker exec $name mclient -d db -i /tmp/03_01_load.sql
done

# delete .monetdb file
echo '## REMOVING ORIGINAL CREDENTIALS FILE ##'
rm .monetdb

echo 'done.'

# create master



# ./02_00_load.sh
# docker rename monetdb-r monetdb-r-w1
#
# # create worker 2
# docker run -d -P --name monetdb-r-w2 --cpus="1" --memory="2g" monetdb/monetdb-r-docker
#
# # create master
# docker run -d -P --name monetdb-r-master --cpus="1" --memory="2g" monetdb/monetdb-r-docker
#
# # stop workers 1 and 2
# docker exec monetdb-r-w1 monetdb stop db
# docker exec monetdb-r-w2 monetdb stop db
#
# # set passphrase
# docker exec monetdb-r-w1 monetdb set passphrase=senha db
# docker exec monetdb-r-w2 monetdb set passphrase=senha db
#
# # share databases
# docker exec monetdb-r-w1 monetdb set shared=db/1/fox db
# docker exec monetdb-r-w2 monetdb set shared=db/2/fox db
#
# # start workers 1 and 2
# docker exec monetdb-r-w1 monetdb start db
# docker exec monetdb-r-w2 monetdb start db
#
# echo "done."
