# This Python file uses the following encoding: utf-8
from pyspark.context import SparkContext
from pyspark.sql.session import SparkSession
from pyspark.sql import functions as F

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
df = df.withColumn('pdate', F.regexp_extract(df.filename, '\d{6}', 0) )

# save csv
df.write.csv(mypath + 'load.csv')
