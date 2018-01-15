# Use this script outside the docker. It needs R installed:
# Rscript 04_ts_all.R

# port to connect with MonetDB
p=32785

# images' directory
img.dir <- "../paper/img/"

# data directory
data.dir <- "../data/"

# used to connect to MonetDB
if (!("MonetDB.R" %in% (installed.packages())[,1]))
  install.packages("MonetDB.R", repos="https://cloud.r-project.org/")

library(MonetDB.R)
library(DBI)


##### Function to create time series
query.ts <- function (name) {
  # connects to MonetDB and retrieves result as a data frame
  cat(paste0("get results for ", name, "..."))

  b <- Sys.time()
  if (name == "BR") {
    query <- paste("SELECT p_date,",
                   "AVG(value) AS mean",
                   "FROM payments",
                   "GROUP BY p_date",
                   "ORDER BY p_date")
  } else {
    query <- paste0("SELECT p_date,",
                    "AVG(value) AS mean",
                    " FROM payments",
                    " WHERE state = '", name, "'",
                    " GROUP BY p_date",
                    " ORDER BY p_date")
  }

    mydf <- mq(host="localhost", port=p, dbname="db", user="monetdb",
               password="monetdb", query)
  e <- Sys.time()

  # gets standard deviation to create confidence intervals
  if (name == "BR") {
    query <- paste("SELECT p_date,",
                   "STDDEV_POP(value) AS mean",
                   "FROM payments",
                   "GROUP BY p_date",
                   "ORDER BY p_date")
  } else {
    query <- paste0("SELECT p_date,",
                    "STDDEV_POP(value) AS mean",
                    " FROM payments",
                    " WHERE state = '", name, "'",
                    " GROUP BY p_date",
                    " ORDER BY p_date")
  }
  mysd <- mq(host="localhost", port=p, dbname="db", user="monetdb",
             password="monetdb", query)



  cat(paste("done. Time elapsed:", format(e - b, digits=5), "\n"))

  # creates a time series object
  myts <- ts(mydf$mean, start=c(2011, 1), end=c(2017, 2), frequency=12)

  # saves a time series plot
  pdf(paste0(name, "_pop.pdf"))
    plot(myts)
  ignore <- dev.off()

  # saves data frame
  write.csv(mydf, paste0(data.dir, name, "_pop.csv"), row.names=FALSE)
  
  # return(myts)
}

##### Full Time Series #####
query.ts("BR")

##### Time Series per State

# get all states
states <- mq(host="localhost", port=p, dbname="db", user="monetdb", password="monetdb",
           "SELECT DISTINCT state FROM payments ORDER BY state")

for (i in 1:nrow(states)) {
  query.ts(states$state[i])
}


# RANDOM SAMPLE BR
t1=Sys.time()
bd_random <- mq(host="localhost",  port=p, dbname="db", user="monetdb",
                password="monetdb", query="SELECT * FROM payments sample 1347")
Sys.time()-t1

# RANDOM SAMPLE BY UF
t1=Sys.time()
bd_random.estr <- mq(dbname="db",  port=p, user="monetdb",
                     password="monetdb", query="SELECT * FROM payments sample 392080")
Sys.time()-t1

save(bd_random, file = paste0(data.dir,"bd_random.RData"))
save(bd_random.estr, file = paste0(data.dir,"bd_random.strat.RData"))
