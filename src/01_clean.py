# This Python file uses the following encoding: utf-8
import csv
import codecs
from os import listdir
from os.path import isfile, join

# get list of csv files
mypath = '/media/mourao/BACKUP1/bolsa_familia/'
files = [f for f in listdir(mypath) if isfile(join(mypath, f)) and f[-3:] == 'csv']
files.sort()

# create a new csv with less columns from list of csv files
load = open(mypath + 'load.csv', 'w')
fieldnames = ['date', 'payee', 'state', 'value']
writer = csv.DictWriter(load, fieldnames=fieldnames)

# writer.writeheader()
for file in files:
    print(file)
    csvfile = codecs.open(mypath + file, 'r', 'iso-8859-1')
    reader = csv.DictReader(csvfile, delimiter='\t', quotechar=' ')
    for row in reader:
        date = file[:4] + '-' + file[4:6] + '-01'
        state = row.get('UF', '')
        payee = row.get('NIS Favorecido')
        value = (row.get('Valor Parcela', '')).replace(',', '')
        writer.writerow({'date': date, 'payee': payee, 'state': state, 'value': value})
    csvfile.close()

load.close()
