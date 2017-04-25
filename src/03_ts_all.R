# Use this script outside the docker. It needs R installed:
# Rscript 03_ts_all.R

dir <- "../paper/img/"

if (!("MonetDB.R" %in% (installed.packages())[,1])) install.packages("MonetDB.R", repos="https://cloud.r-project.org/")

library(MonetDB.R)
library(DBI)

x <- mq(host="localhost", port=32772, dbname="db", user="monetdb", password="monetdb", "SELECT payment_date, avg(value) as mean from payments group by payment_date")

myts <- ts(x$mean, start=c(2011, 1), end=c(2017, 2), frequency=12)

pdf(paste0(dir, "ts.pdf"))
  plot(myts)
ignore <- dev.off()
