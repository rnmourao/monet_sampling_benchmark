#!/bin/sh

# needs to be root to execute this script: sudo ./03_00_load_remote.sh
# uses Docker version 17.03.1-ce, build c6d412e

# change this path
csvfile=/home/mourao/monet_sampling_benchmark/data
# csvfile=/media/mourao/BACKUP/bolsa_familia/load

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
awk -F, '{print > "'$csvfile'/"substr($2,1,4)".csv"}' $csvfile/load.csv

# create workers
echo '## CREATING WORKERS ##'
link=""
for i in $( ls -1 $csvfile/20*.csv | grep -o '.\{8\}$' | cut -d. -f1 ); do
  name=monetdb-$i
  link="$link --link $name:$name"

  # create temp file with remote table statement
  echo "CREATE REMOTE TABLE t$i (state char(2), p_date date, payee bigint, value decimal(7,2), log_value decimal(18,16)) on 'mapi:monetdb://$name:50000/db';" >> temp
  echo "ALTER TABLE payments ADD TABLE t$i;" >> temp

  # execute docker and mounts csv file
  echo '## STARTING WORKER '$name' ##'
  docker run -d -P --name $name --cpus='1' --memory='2g' -v $csvfile:/tmp/data:ro  monetdb/monetdb-r-docker

  echo '## WAITING ##'
  sleep 30

  # copy .monetdb into docker
  echo '## COPYING CREDENTIALS FILE ##'
  docker cp .monetdb $name:/root/.monetdb

  # copy load.sql into docker
  echo '## COPYING DDL SCRIPT INTO WORKER ##'
  docker cp 03_01_load.sql $name:/tmp/03_01_load.sql

  # change the filename within the load.sql file
  echo '## ADAPTING DDL SCRIPT TO WORKER ##'
  docker exec $name sed -i 's/@YEAR@/'$i'/g' /tmp/03_01_load.sql

  # execute load.sql
  echo '## EXECUTING DDL SCRIPT ##'
  docker exec $name mclient -d db -i /tmp/03_01_load.sql
done

#### create master
echo '## CREATING MASTER DB ##'
echo $link
docker run -d -P --name monetdb-master $link --cpus='1' --memory='2g' monetdb/monetdb-r-docker

echo '## WAITING ##'
sleep 30

# copy .monetdb into docker
echo '## COPYING CREDENTIALS FILE ##'
docker cp .monetdb monetdb-master:/root/.monetdb

# copy load.sql into docker
echo '## COPYING DDL SCRIPT INTO MASTER ##'
docker cp 03_02_load.sql monetdb-master:/tmp/03_02_load.sql

# copy temp file into docker
docker cp temp monetdb-master:/tmp/temp

# join the two files
docker exec monetdb-master bash -c "cd tmp && sed -i '/REMOTE TABLES/r temp' 03_02_load.sql"

# execute load.sql
echo '## EXECUTING DDL SCRIPT ##'
docker exec monetdb-master mclient -d db -i /tmp/03_02_load.sql

# delete .monetdb file
echo '## REMOVING TEMPORARY FILES ##'
rm .monetdb
rm temp

echo 'done.'
