# This Python file uses the following encoding: utf-8
from pyspark.context import SparkContext
from pyspark.sql.session import SparkSession
from pyspark.sql import functions as F
import matplotlib.pyplot as plt
import pandas as pd

# csv files' path
mypath = '/media/mourao/BACKUP/bolsa_familia/'
# mypath = '/media/mourao/BACKUP/bolsa_familia/test/'

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

# create double column 'value' from 'Valor Parcela'
df = df.withColumn('value', df['Valor Parcela'].cast('double'))

# create a log-transformed column of value
df = df.withColumn('log_value', F.log(10.0, df['value']))

### save csv
df2 = df.select('UF', 'pdate', 'NIS Favorecido', 'value', 'log_value')
df2.repartition(1) \
.write \
.format("com.databricks.spark.csv") \
.save(mypath + 'load')

# statistics from population
print('Statistics about value:')
df.select([F.mean('value'), F.stddev_pop('value'), \
           F.skewness('value'), F.kurtosis('value')]).show()

print('Statistics about log(value):')
df.select([F.mean('log_value'), F.stddev_pop('log_value'), \
           F.skewness('log_value'), F.kurtosis('log_value')]).show()

# plot histograms
n_bins = 20
fig, axes = plt.subplots(nrows=1, ncols=2)
ax0, ax1 = axes.flatten()

ax0.hist(df.toPandas()['value'], n_bins)
ax0.set_title('value')

ax1.hist(df.toPandas()['log_value'], n_bins)
ax1.set_title('log(value)')

fig.tight_layout()
plt.savefig("../paper/img/hist.pdf")
