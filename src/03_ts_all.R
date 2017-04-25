# Use this script outside the docker. It needs R installed:
# Rscript 03_ts_all.R

# images' directory 
dir <- "../paper/img/"

# used to connect to MonetDB
if (!("MonetDB.R" %in% (installed.packages())[,1])) 
  install.packages("MonetDB.R", repos="https://cloud.r-project.org/")

library(MonetDB.R)
library(DBI)


##### Function to create time series
query.ts <- function (name, query) {
  
  # connects to MonetDB and retrieves result as a data frame
  cat(paste0("get results of ", name, "..."))
  
  b <- Sys.time()
  mydf <- mq(host="localhost", port=32772, dbname="db", user="monetdb", 
             password="monetdb", query)
  e <- Sys.time()
  cat(paste("done. Time elapsed:", format(e - b, digits=5), "\n"))
  
  # creates a time series object
  myts <- ts(mydf$mean, start=c(2011, 1), end=c(2017, 2), frequency=12)
  
  # saves a time series plot
  pdf(paste0(dir, name, ".pdf"))
    plot(myts)
  ignore <- dev.off()

}

##### Full Time Series #####
query.ts("BR", 
         paste("SELECT payment_date",
                    ", AVG(value) AS mean", 
               "FROM payments",
               "GROUP BY payment_date",
               "ORDER BY payment_date"))

##### Time Series per State

# get all states
states <- mq(host="localhost", port=32772, dbname="db", user="monetdb", password="monetdb", 
           "SELECT DISTINCT state FROM payments ORDER BY state")

for (i in 1:nrow(states)) {
  st <- states$state[i]
  query.ts(st, 
           paste0("SELECT payment_date, AVG(value) AS mean",
                 " FROM payments",
                 " WHERE state = '", st, "'",
                 " GROUP BY payment_date", 
                 " ORDER BY payment_date"))
}