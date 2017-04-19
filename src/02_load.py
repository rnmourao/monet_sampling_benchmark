import logging

#configure the logger, so we can see what is happening
logging.basicConfig(level=logging.DEBUG)
logger = logging.getLogger('monetdb')

import pymonetdb

conn = pymonetdb.connect(username="monetdb", password="monetdb", port="32771", hostname="0.0.0.0", database="bdm")
cursor = conn.cursor()

cursor.execute('CREATE TABLE "payments" ("payment_date" date, "state" char(2), "payee" bigint, "value" decimal(7,2));');
