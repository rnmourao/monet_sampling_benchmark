# Use this script outside the docker. It needs R installed:
# Rscript 03_ts_sample.R

# images' directory 
img.dir <- "../paper/img/"

# data directory
data.dir <- "../data/"

# size of samples
size <- 4000

# used to connect to MonetDB
if (!("MonetDB.R" %in% (installed.packages())[,1])) 
  install.packages("MonetDB.R", repos="https://cloud.r-project.org/")

# used to test samples randomness
if (!("randtests" %in% (installed.packages())[,1])) 
  install.packages("randtests", repos="https://cloud.r-project.org/")

library(MonetDB.R)
library(randtests)
library(DBI)


##### Function to create time series from samples
sample.ts <- function(name) {
  # connects to MonetDB and retrieves result as a data frame
  cat(paste0("get results for ", name, "..."))
  
  b <- Sys.time()
    mydf <- NULL
    for (d in 1:nrow(dates)) {
      if (name == "BR") {
        query <- paste0("SELECT value",
                        " FROM payments",
                        " WHERE payment_date = '", dates$payment_date[d], "'",
                        " SAMPLE ", size)
      } else {
        query <- paste0("SELECT value",
                        " FROM payments",
                        " WHERE state = '", name, "'",
                        " AND payment_date = '", dates$payment_date[d], "'",
                        " SAMPLE ", size)
      }
      
      values <- mq(host="localhost", port=32771, dbname="db", user="monetdb", 
                   password="monetdb", query)
      
      m <- mean(values$value) 
      
      if (is.null(mydf)) {
        mydf <- data.frame(payment_date = dates$payment_date[d], mean = m)
      } else {
        mydf <- rbind(mydf, data.frame(payment_date = dates$payment_date[d], mean = m))      
      }
      
    }
  e <- Sys.time()
  
  cat(paste("done. Time elapsed:", format(e - b, digits=5), "\n"))
  
  # creates a time series object
  myts <- ts(mydf$mean, start=c(2011, 1), end=c(2017, 2), frequency=12)
  
  # saves a time series plot
  pdf(paste0(img.dir, name, "_sam.pdf"))
  plot(myts)
  ignore <- dev.off()
  
  # saves data frame
  write.csv(mydf, paste0(data.dir, name, "_sam.csv"), row.names=FALSE)
}

# get all dates
dates <- mq(host="localhost", port=32771, dbname="db", user="monetdb", password="monetdb", 
             "SELECT DISTINCT payment_date FROM payments ORDER BY payment_date")

# get all states
states <- mq(host="localhost", port=32771, dbname="db", user="monetdb", password="monetdb", 
             "SELECT DISTINCT state FROM payments ORDER BY state")

##### Full Time Series #####
sample.ts("BR")

##### Time Series per State
for (i in 1:nrow(states)) {
  st <- states$state[i]
  sample.ts(st)
}