#!/bin/sh

# join id file with data file

# change this path
csvfile=/media/mourao/BACKUP/bolsa_familia
# csvfile=/media/mourao/BACKUP/bolsa_familia/test

# join files
paste -d',' $csvfile/load/part*.csv $csvfile/ids.txt > $csvfile/load/load.csv
# rm $csvfile/ids.txt $csvfile/load/part*.csv

echo '## DONE. ##'
