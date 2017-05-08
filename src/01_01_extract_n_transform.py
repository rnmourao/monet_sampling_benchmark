# This Python file uses the following encoding: utf-8
from pyspark.context import SparkContext
from pyspark.sql.session import SparkSession
from pyspark.sql import functions as F

# csv files' path
# mypath = '/media/mourao/BACKUP/bolsa_familia/'
mypath = '/home/f8676628/Downloads/'

# create SparkContext and SparkSession to process files
sc = SparkContext('local','example')
spark = SparkSession(sc)

# join all csv files in a unique dataframe.
df = spark.read.format('csv') \
    .option('schema', 'StructType([StructField("uf", StringType(), False), \
                                   StructField("pdate", DateType(), False), \
                                   StructField("nis", StringType(), False), \
                                   StructField("value", DecimalType(5, 2), False), \
                                   StructField("logvalue", DoubleType(), False)])') \
    .option('sep', ',') \
    .option('header', 'False') \
    .load(mypath + 'load.csv')

# identify payee's first appearance
def is_newcomer(nis, pdate):
    if pdate ==  '2011-01-01':
        return "S"
    else:
        count = df.filter(df.NIS == nis).filter(df.pdate < pdate).count()
        if count == 0:
            return "S"
        else:
            return "N"

newcomer = udf(is_newcomer, StringType())
new_df = df.withColumn('newcomer', newcomer(df.NIS, df.p_date))

# save csv
out = df.select('uf', 'pdate', 'nis', 'value', 'newcomer')
out.repartition(1) \
   .write \
  .format("com.databricks.spark.csv") \
  .save(mypath + 'load2')
