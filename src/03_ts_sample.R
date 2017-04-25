# Use this script outside the docker. It needs R installed:
# Rscript 03_ts_sample.R

# images' directory 
dir <- "../paper/img/"

# used to connect to MonetDB
if (!("MonetDB.R" %in% (installed.packages())[,1])) 
  install.packages("MonetDB.R", repos="https://cloud.r-project.org/")

# used to test samples randomness
if (!("randtests" %in% (installed.packages())[,1])) 
  install.packages("MonetDB.R", repos="https://cloud.r-project.org/")

