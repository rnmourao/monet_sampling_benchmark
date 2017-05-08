# This Python file uses the following encoding: utf-8
from pyspark.context import SparkContext
from pyspark.sql.session import SparkSession
from pyspark.sql import functions as F
import matplotlib.pyplot as plt
import pandas as pd

# csv files' path
# mypath = '/media/mourao/BACKUP/bolsa_familia/'
mypath = '/media/mourao/BACKUP/bolsa_familia/test/'

# create SparkContext and SparkSession to process files
sc = SparkContext('local','example')
spark = SparkSession(sc)

# join all csv files in a unique dataframe.
df = spark.read.format('csv') \
    .option('charset', 'iso-8859-1') \
    .option('sep', '\t') \
    .option('header', 'True') \
    .load(mypath + '*.csv') \
    .withColumn('filename', F.input_file_name())

# extract date
df = df.withColumn('pdate', F.concat(F.regexp_extract(df.filename, '\d{4}', 0), \
                                     F.lit('-'), \
                                     F.regexp_extract(df.filename, '(\d{2})(?!.*\d)', 0), \
                                     F.lit('-01')))

# dates = [d for d in df.select('p_date').distinct().collect]
# dates.sort()

def is_newcomer(nis, p_date):
    return "S"

newcomer = udf(is_newcomer, StringType())
new_df = df.withColumn('newcomer', newcomer(df.NIS, df.p_date))

### save csv
# df2 = df.select('UF', 'pdate', 'NIS Favorecido', 'value', 'newcomer')
# df2.repartition(1) \
# .write \
# .format("com.databricks.spark.csv") \
# .save(mypath + 'load')
