#!/bin/sh

# join id file with data file

# change this path
# csvfile=/media/mourao/BACKUP/bolsa_familia
csvfile=/media/mourao/BACKUP/bolsa_familia/test

# join files
paste -d',' $csvfile/ids.txt $csvfile/load/part*.csv > $csvfile/load/load.csv

echo '## DONE. ##'
