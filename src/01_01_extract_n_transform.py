# This Python file uses the following encoding: utf-8
from pyspark.context import SparkContext
from pyspark.sql.session import SparkSession
from pyspark.sql import functions as F
from pyspark.sql import types as T
from datetime import datetime

# csv files' path
mypath = '/media/mourao/BACKUP/bolsa_familia/load/'
# mypath = '/home/mourao/monet_sampling_benchmark/data/'

# create SparkContext and SparkSession to process files
sc = SparkContext('local','example')
spark = SparkSession(sc)

schema = T.StructType([T.StructField("uf", T.StringType()), \
                               T.StructField("pdate", T.DateType()), \
                               T.StructField("nis", T.LongType()), \
                               T.StructField("value", T.DecimalType(5, 2)), \
                               T.StructField("logvalue", T.DoubleType())])

# join all csv files in a unique dataframe.
print('## READ CSV FILE ##')
df = spark.read.csv(mypath + 'load.csv', schema)

print('## GET MIN DATE ##')
df.createOrReplaceTempView("table1")
df2 = spark.sql("SELECT nis, min(pdate) as min_pdate from table1 group by nis")
df = df.join(df2, 'nis', 'inner')

def is_newcomer(pdate, min_pdate):
    if pdate == min_pdate:
        return 1
    else:
        return 0

is_newcomer_udf = F.udf(is_newcomer, T.IntegerType())
df = df.withColumn('newcomer', is_newcomer_udf(df.pdate, df.min_pdate))

print('## GET MAX DATE ##')
df3 = spark.sql("SELECT nis, max(pdate) as max_pdate from table1 group by nis")
df = df.join(df3, 'nis', 'inner')
def is_freshout(pdate, max_pdate):
    if pdate == max_pdate:
        return -1
    else:
        return 0

is_freshout_udf = F.udf(is_freshout, T.IntegerType())
df = df.withColumn('freshout', is_freshout_udf(df.pdate, df.max_pdate))

# save csv
print('## SAVE NEW CSV FILE ##')
out = df.select('uf', 'pdate', 'nis', 'value', 'newcomer', 'freshout')

out.repartition(1) \
   .write \
  .format("com.databricks.spark.csv") \
  .save(mypath + 'load2')

print('## DONE. ' + str(datetime.now()) + ' ##' )
