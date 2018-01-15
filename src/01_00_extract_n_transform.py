# This Python file uses the following encoding: utf-8
from pyspark.context import SparkContext
from pyspark.sql.session import SparkSession
from pyspark.sql import functions as F
from pyspark.sql import types as T
from datetime import datetime

# csv files' path
mypath = '/media/mourao/BACKUP/bolsa_familia/test/'
# mypath = '/media/mourao/BACKUP/bolsa_familia/'

# create SparkContext and SparkSession to process files
sc = SparkContext('local','example')
spark = SparkSession(sc)

# join all csv files in a unique dataframe.
print('## READ CSV FILE ##')
df = spark.read.format('csv') \
    .option('charset', 'iso-8859-1') \
    .option('sep', '\t') \
    .option('header', 'True') \
    .load(mypath + '*.csv') \
    .withColumn('filename', F.input_file_name())

# extract date
df = df.withColumn('pdate', F.date_format(F.concat(F.regexp_extract(df.filename, '\d{4}', 0), \
                                     F.lit('-'), \
                                     F.regexp_extract(df.filename, '(\d{2})(?!.*\d)', 0), \
                                     F.lit('-01')), 'yyyy-MM-dd'))

# create double column 'value' from 'Valor Parcela'
print('## CREATE VALUE COLUMN ##')
df = df.withColumn('value', df['Valor Parcela'].cast('double'))

print('## GET MIN AND MAX DATE PER ID ##')
df.createOrReplaceTempView("table1")
df2 = spark.sql("SELECT `NIS Favorecido`, \
                        min(pdate) as min_pdate, \
                        max(pdate) as max_pdate  \
                        from table1 group by `NIS Favorecido`")
df = df.join(df2, 'NIS Favorecido', 'inner')

def is_newcomer(pdate, min_pdate):
    if pdate == min_pdate:
        return 1
    else:
        return 0

is_newcomer_udf = F.udf(is_newcomer, T.IntegerType())
df = df.withColumn('newcomer', is_newcomer_udf(df.pdate, df.min_pdate))

def is_freshout(pdate, max_pdate):
    if pdate == max_pdate:
        return 1
    else:
        return 0

is_freshout_udf = F.udf(is_freshout, T.IntegerType())
df = df.withColumn('freshout', is_freshout_udf(df.pdate, df.max_pdate))

# save data csv
print('## SAVE NEW CSV FILE ##')
out = df.select('UF', 'pdate', 'NIS Favorecido', 'value', 'newcomer', 'freshout').orderBy(['UF', 'pdate', 'NIS Favorecido'])
out.repartition(1) \
.write \
.format("com.databricks.spark.csv") \
.save(mypath + 'load')

# create file with ids
with open(mypath + 'ids.txt', mode='w') as myfile:
    myfile.write('\n'.join([str(i + 1) for i in range(df.count())]))

print('## DONE. ' + str(datetime.now()) + ' ##' )
